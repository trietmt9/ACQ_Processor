#include "ApplicationController.h"
#include <QFileInfo>
#include <QDir>
#include <QStandardPaths>
#include <QPointF>
#include <iostream>
#include <fstream>
#include <iomanip>

ApplicationController::ApplicationController(QObject *parent)
    : QObject(parent)
    , m_isLoading(false)
    , m_pythonProcess(nullptr)
{
    // Create temp directory for converted files
    QString tempPath = QStandardPaths::writableLocation(QStandardPaths::TempLocation);
    m_tempOutputDir = tempPath + "/acq_processor_temp";
    QDir().mkpath(m_tempOutputDir);

    std::cout << "Temp directory: " << m_tempOutputDir.toStdString() << std::endl;
}

ApplicationController::~ApplicationController() {
    if (m_pythonProcess) {
        m_pythonProcess->kill();
        m_pythonProcess->waitForFinished();
        delete m_pythonProcess;
    }
}

void ApplicationController::setStatusMessage(const QString& message) {
    if (m_statusMessage != message) {
        m_statusMessage = message;
        emit statusMessageChanged();
        std::cout << "Status: " << message.toStdString() << std::endl;
    }
}

void ApplicationController::setIsLoading(bool loading) {
    if (m_isLoading != loading) {
        m_isLoading = loading;
        emit isLoadingChanged();
    }
}

void ApplicationController::setChannelData(std::shared_ptr<ChannelData> data) {
    m_channelData = data;
    emit hasDataChanged();
    emit sampleRateChanged();
    emit numSamplesChanged();
    emit waveformUpdated();
}

bool ApplicationController::loadACQFile(const QString& acqFilePath) {
    QFileInfo fileInfo(acqFilePath);

    if (!fileInfo.exists()) {
        setStatusMessage("Error: File does not exist");
        emit conversionFailed("File not found: " + acqFilePath);
        return false;
    }

    if (!fileInfo.suffix().toLower().contains("acq")) {
        setStatusMessage("Error: Not an ACQ file");
        emit conversionFailed("Invalid file type");
        return false;
    }

    m_currentFile = acqFilePath;
    emit currentFileChanged();

    setIsLoading(true);
    setStatusMessage("Converting ACQ file...");

    // Call Python converter
    return callPythonConverter(acqFilePath);
}

bool ApplicationController::callPythonConverter(const QString& acqFilePath) {
    // Clear temp directory before conversion to avoid stale data
    QDir tempDir(m_tempOutputDir);
    if (tempDir.exists()) {
        std::cout << "Cleaning temp directory..." << std::endl;
        tempDir.removeRecursively();
        tempDir.mkpath(".");
    }

    // Find Python converter script
    QString scriptPath = QDir::currentPath() + "/python/batch_acq_converter.py";

    // Check if script exists
    if (!QFile::exists(scriptPath)) {
        // Try alternative path
        scriptPath = QDir::currentPath() + "/../python/batch_acq_converter.py";
        if (!QFile::exists(scriptPath)) {
            setStatusMessage("Error: Python converter not found");
            setIsLoading(false);
            emit conversionFailed("Converter script not found");
            return false;
        }
    }

    // Create Python process
    if (m_pythonProcess) {
        delete m_pythonProcess;
    }

    m_pythonProcess = new QProcess(this);

    // Connect signals
    connect(m_pythonProcess, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, &ApplicationController::onPythonProcessFinished);
    connect(m_pythonProcess, &QProcess::errorOccurred,
            this, &ApplicationController::onPythonProcessError);
    connect(m_pythonProcess, &QProcess::readyReadStandardOutput,
            this, &ApplicationController::onPythonProcessOutput);

    // Check for virtual environment
    QString pythonCmd = "python3";
    QString venvPath = QDir::homePath() + "/.pyvenv/bin/python3";
    if (QFile::exists(venvPath)) {
        pythonCmd = venvPath;
        std::cout << "Using virtual environment Python" << std::endl;
    }

    // Build command
    QStringList arguments;
    arguments << scriptPath;
    arguments << m_tempOutputDir;
    arguments << acqFilePath;

    std::cout << "Running: " << pythonCmd.toStdString() << " "
              << arguments.join(" ").toStdString() << std::endl;

    // Start process
    m_pythonProcess->start(pythonCmd, arguments);

    if (!m_pythonProcess->waitForStarted(5000)) {
        setStatusMessage("Error: Failed to start Python converter");
        setIsLoading(false);
        emit conversionFailed("Failed to start converter");
        return false;
    }

    emit conversionProgress(10, "Converting ACQ file...");
    return true;
}

void ApplicationController::onPythonProcessOutput() {
    if (!m_pythonProcess) return;

    QString output = m_pythonProcess->readAllStandardOutput();
    std::cout << output.toStdString();

    // Update progress based on output
    if (output.contains("Processing channel")) {
        emit conversionProgress(50, "Processing channels...");
    } else if (output.contains("Successfully processed")) {
        emit conversionProgress(90, "Finalizing...");
    }
}

void ApplicationController::onPythonProcessFinished(int exitCode, QProcess::ExitStatus exitStatus) {
    setIsLoading(false);

    if (exitStatus == QProcess::CrashExit || exitCode != 0) {
        QString error = m_pythonProcess ? m_pythonProcess->readAllStandardError() : "";
        setStatusMessage("Error: Conversion failed");
        std::cerr << "Converter error: " << error.toStdString() << std::endl;
        emit conversionFailed("Conversion failed: " + error);
        return;
    }

    emit conversionProgress(100, "Loading data...");

    // Load converted data
    if (loadConvertedData()) {
        setStatusMessage("File loaded successfully");
        emit conversionComplete();
    } else {
        setStatusMessage("Error: Failed to load converted data");
        emit conversionFailed("Failed to load data");
    }
}

void ApplicationController::onPythonProcessError(QProcess::ProcessError error) {
    setIsLoading(false);

    QString errorMsg;
    switch (error) {
        case QProcess::FailedToStart:
            errorMsg = "Python converter failed to start";
            break;
        case QProcess::Crashed:
            errorMsg = "Python converter crashed";
            break;
        case QProcess::Timedout:
            errorMsg = "Python converter timed out";
            break;
        default:
            errorMsg = "Python converter error";
    }

    setStatusMessage("Error: " + errorMsg);
    emit conversionFailed(errorMsg);
}

bool ApplicationController::loadConvertedData() {
    // Load metadata.json from temp directory
    QString metadataPath = m_tempOutputDir + "/metadata.json";

    if (!QFile::exists(metadataPath)) {
        std::cerr << "Metadata file not found: " << metadataPath.toStdString() << std::endl;
        return false;
    }

    auto metadata = m_loader.loadMetadata(metadataPath.toStdString());
    if (!metadata) {
        std::cerr << "Failed to parse metadata" << std::endl;
        return false;
    }

    const auto& files = metadata->getFiles();
    if (files.empty()) {
        std::cerr << "No files in metadata" << std::endl;
        return false;
    }

    // Load last file (the one we just converted - most recently added)
    auto fileMetadata = files[files.size() - 1];

    std::cout << "Loading file: " << fileMetadata->getSourceFile()
              << " (" << fileMetadata->getNumChannels() << " channels)" << std::endl;

    bool success = m_loader.loadBinaryData(fileMetadata, m_tempOutputDir.toStdString());

    if (!success) {
        std::cerr << "Failed to load binary data" << std::endl;
        return false;
    }

    const auto& channels = fileMetadata->getChannels();
    if (channels.empty()) {
        std::cerr << "No channels found" << std::endl;
        return false;
    }

    // Load first channel
    m_channelData = channels[0];
    m_originalData = std::make_shared<ChannelData>(*m_channelData);  // Keep original copy

    std::cout << "Loaded channel: " << m_channelData->getName() << std::endl;
    std::cout << "Samples: " << m_channelData->getNumSamples() << std::endl;
    std::cout << "Sample rate: " << m_channelData->getSampleRate() << " Hz" << std::endl;
    std::cout << "Data range: [" << m_channelData->getMin() << ", "
              << m_channelData->getMax() << "]" << std::endl;
    std::cout << "Mean: " << m_channelData->getMean() << ", Std: "
              << m_channelData->getStd() << std::endl;

    // Print first few samples for verification
    const auto& data = m_channelData->getData();
    if (!data.empty()) {
        std::cout << "First 10 samples: ";
        for (size_t i = 0; i < std::min(size_t(10), data.size()); ++i) {
            std::cout << data[i] << " ";
        }
        std::cout << std::endl;
    } else {
        std::cerr << "WARNING: Channel data is empty!" << std::endl;
    }

    emit hasDataChanged();
    emit sampleRateChanged();
    emit numSamplesChanged();
    emit waveformUpdated();

    return true;
}

QVariantList ApplicationController::vectorToVariantList(const std::vector<float>& data, int maxPoints) {
    QVariantList result;

    if (data.empty()) {
        return result;
    }

    size_t numPoints = data.size();

    // Downsample if needed
    if (maxPoints > 0 && static_cast<int>(numPoints) > maxPoints) {
        int step = numPoints / maxPoints;
        for (size_t i = 0; i < numPoints; i += step) {
            result.append(QPointF(i, data[i]));
        }
        // Always include last point
        if (numPoints - 1 != result.last().toPointF().x()) {
            result.append(QPointF(numPoints - 1, data.back()));
        }
    } else {
        // Return all points
        for (size_t i = 0; i < numPoints; ++i) {
            result.append(QPointF(i, data[i]));
        }
    }

    return result;
}

QVariantList ApplicationController::getWaveformData(int maxPoints) {
    if (!m_channelData || m_channelData->getData().empty()) {
        return QVariantList();
    }

    return vectorToVariantList(m_channelData->getData(), maxPoints);
}

QVariantList ApplicationController::getCurrentWaveformData(int maxPoints) {
    return getWaveformData(maxPoints);
}

void ApplicationController::updateWaveform(const std::vector<float>& filteredData) {
    if (!m_channelData) {
        return;
    }

    std::cout << "Updating waveform with " << filteredData.size() << " filtered samples" << std::endl;

    // Update channel data with filtered data
    m_channelData->setData(filteredData);

    // Update label manager voltage data
    emit waveformUpdated();
}

void ApplicationController::applyFilteredData(const QVariantList& filteredPoints) {
    if (!m_channelData) {
        std::cerr << "ERROR: No channel data available" << std::endl;
        return;
    }

    std::cout << "Applying filtered data from QML: " << filteredPoints.size() << " points" << std::endl;

    // Extract voltage values from QPointF list
    std::vector<float> voltageData;
    voltageData.reserve(filteredPoints.size());

    for (const auto& point : filteredPoints) {
        QPointF p = point.toPointF();
        voltageData.push_back(p.y());
    }

    std::cout << "Extracted " << voltageData.size() << " voltage samples" << std::endl;

    if (!voltageData.empty()) {
        // Show first few values for debugging
        std::cout << "First 5 filtered values: ";
        for (size_t i = 0; i < std::min(size_t(5), voltageData.size()); ++i) {
            std::cout << voltageData[i] << " ";
        }
        std::cout << std::endl;

        // Update the waveform
        updateWaveform(voltageData);
    } else {
        std::cerr << "ERROR: No voltage data extracted from filtered points" << std::endl;
    }
}

void ApplicationController::resetToOriginal() {
    if (!m_originalData) {
        std::cerr << "ERROR: No original data available to reset" << std::endl;
        return;
    }

    std::cout << "Resetting to original unfiltered data..." << std::endl;

    // Create a fresh copy of the original data
    m_channelData = std::make_shared<ChannelData>(*m_originalData);

    std::cout << "  Restored " << m_channelData->getNumSamples() << " samples" << std::endl;
    std::cout << "  Sample rate: " << m_channelData->getSampleRate() << " Hz" << std::endl;

    // Notify UI that waveform has been updated
    emit hasDataChanged();
    emit waveformUpdated();

    std::cout << "Reset to original data complete" << std::endl;
}

bool ApplicationController::exportToCSV(const QString& filePath) {
    if (!m_channelData) {
        std::cerr << "ERROR: No data to export" << std::endl;
        return false;
    }

    std::cout << "Exporting data to CSV: " << filePath.toStdString() << std::endl;

    std::ofstream file(filePath.toStdString());
    if (!file.is_open()) {
        std::cerr << "ERROR: Failed to open file for writing: " << filePath.toStdString() << std::endl;
        return false;
    }

    // Write header
    file << "Time (s),Amplitude (mV)" << std::endl;

    // Write data
    const auto& data = m_channelData->getData();
    float sampleRate = m_channelData->getSampleRate();

    for (size_t i = 0; i < data.size(); ++i) {
        float time = static_cast<float>(i) / sampleRate;
        file << std::fixed << std::setprecision(6) << time << ","
             << std::setprecision(6) << data[i] << std::endl;
    }

    file.close();

    std::cout << "✓ Successfully exported " << data.size() << " samples to " << filePath.toStdString() << std::endl;
    return true;
}
