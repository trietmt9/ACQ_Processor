#ifndef APPLICATIONCONTROLLER_H
#define APPLICATIONCONTROLLER_H

#include <QObject>
#include <QString>
#include <QProcess>
#include <QVariantList>
#include <memory>
#include "ChannelData.h"
#include "ACQMetadata.h"
#include "ACQDataLoader.h"

/**
 * @brief Main application controller
 * Handles ACQ file loading, Python conversion, and data management
 */
class ApplicationController : public QObject {
    Q_OBJECT

    Q_PROPERTY(QString currentFile READ currentFile NOTIFY currentFileChanged)
    Q_PROPERTY(bool isLoading READ isLoading NOTIFY isLoadingChanged)
    Q_PROPERTY(QString statusMessage READ statusMessage NOTIFY statusMessageChanged)
    Q_PROPERTY(bool hasData READ hasData NOTIFY hasDataChanged)
    Q_PROPERTY(float sampleRate READ sampleRate NOTIFY sampleRateChanged)
    Q_PROPERTY(int numSamples READ numSamples NOTIFY numSamplesChanged)

public:
    explicit ApplicationController(QObject *parent = nullptr);
    ~ApplicationController();

    // Property getters
    QString currentFile() const { return m_currentFile; }
    bool isLoading() const { return m_isLoading; }
    QString statusMessage() const { return m_statusMessage; }
    bool hasData() const { return m_channelData != nullptr && !m_channelData->getData().empty(); }
    float sampleRate() const { return m_channelData ? m_channelData->getSampleRate() : 0.0f; }
    int numSamples() const { return m_channelData ? m_channelData->getNumSamples() : 0; }

    // Get channel data for filtering
    std::shared_ptr<ChannelData> getChannelData() const { return m_channelData; }
    std::shared_ptr<ChannelData> getOriginalData() const { return m_originalData; }
    void setChannelData(std::shared_ptr<ChannelData> data);

    /**
     * @brief Load ACQ file (automatically converts using Python)
     * @param acqFilePath Path to .acq file
     * @return true if loading started successfully
     */
    Q_INVOKABLE bool loadACQFile(const QString& acqFilePath);

    /**
     * @brief Get waveform data for plotting
     * @param maxPoints Maximum points to return (for downsampling)
     * @return QVariantList of QPointF for chart
     */
    Q_INVOKABLE QVariantList getWaveformData(int maxPoints = 10000);

    /**
     * @brief Get current (possibly filtered) waveform data
     */
    Q_INVOKABLE QVariantList getCurrentWaveformData(int maxPoints = 10000);

    /**
     * @brief Update waveform with filtered data (from C++)
     */
    void updateWaveform(const std::vector<float>& filteredData);

    /**
     * @brief Update waveform with filtered data (from QML)
     */
    Q_INVOKABLE void applyFilteredData(const QVariantList& filteredPoints);

    /**
     * @brief Reset to original unfiltered data
     */
    Q_INVOKABLE void resetToOriginal();

    /**
     * @brief Export waveform data to CSV file
     */
    Q_INVOKABLE bool exportToCSV(const QString& filePath);

signals:
    void currentFileChanged();
    void isLoadingChanged();
    void statusMessageChanged();
    void hasDataChanged();
    void sampleRateChanged();
    void numSamplesChanged();
    void conversionProgress(int percent, const QString& message);
    void conversionComplete();
    void conversionFailed(const QString& error);
    void waveformUpdated();

private slots:
    void onPythonProcessFinished(int exitCode, QProcess::ExitStatus exitStatus);
    void onPythonProcessError(QProcess::ProcessError error);
    void onPythonProcessOutput();

private:
    QString m_currentFile;
    bool m_isLoading;
    QString m_statusMessage;
    std::shared_ptr<ChannelData> m_channelData;
    std::shared_ptr<ChannelData> m_originalData;  // Keep original for reset

    QProcess* m_pythonProcess;
    QString m_tempOutputDir;
    ACQDataLoader m_loader;

    void setStatusMessage(const QString& message);
    void setIsLoading(bool loading);
    bool callPythonConverter(const QString& acqFilePath);
    bool loadConvertedData();
    QVariantList vectorToVariantList(const std::vector<float>& data, int maxPoints);
};

#endif // APPLICATIONCONTROLLER_H
