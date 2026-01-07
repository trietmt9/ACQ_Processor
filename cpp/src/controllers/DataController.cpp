#include "DataController.h"
#include "FilterController.h"
#include <QFileInfo>
#include <QDir>
#include <iostream>

DataController::DataController(QObject *parent)
    : QObject(parent)
    , m_totalFiles(0)
    , m_dataLoaded(false)
    , m_currentFileIndex(-1)
    , m_filterController(nullptr)
{
}

DataController::~DataController() {
}

void DataController::setMetadataPath(const QString &path) {
    if (m_metadataPath != path) {
        m_metadataPath = path;
        emit metadataPathChanged();
    }
}

bool DataController::loadMetadata() {
    if (m_metadataPath.isEmpty()) {
        emit errorOccurred("Metadata path is empty");
        return false;
    }

    QFileInfo fileInfo(m_metadataPath);
    if (!fileInfo.exists()) {
        emit errorOccurred("Metadata file does not exist: " + m_metadataPath);
        return false;
    }

    std::cout << "Loading metadata from: " << m_metadataPath.toStdString() << std::endl;

    m_metadata = m_loader.loadMetadata(m_metadataPath.toStdString());

    if (!m_metadata) {
        emit errorOccurred(QString::fromStdString(m_loader.getLastError()));
        return false;
    }

    m_totalFiles = m_metadata->getTotalFilesProcessed();
    m_dataLoaded = true;

    emit totalFilesChanged();
    emit dataLoadedChanged();

    updateFileList();

    std::cout << "Successfully loaded " << m_totalFiles << " files" << std::endl;
    return true;
}

bool DataController::loadBinaryData(int fileIndex) {
    if (!m_metadata) {
        emit errorOccurred("No metadata loaded");
        return false;
    }

    const auto& files = m_metadata->getFiles();
    if (fileIndex < 0 || fileIndex >= static_cast<int>(files.size())) {
        emit errorOccurred("Invalid file index");
        return false;
    }

    // Get directory containing metadata file
    QFileInfo fileInfo(m_metadataPath);
    QString dataDir = fileInfo.absolutePath();

    auto fileMetadata = files[fileIndex];
    bool success = m_loader.loadBinaryData(fileMetadata, dataDir.toStdString());

    if (!success) {
        emit errorOccurred(QString::fromStdString(m_loader.getLastError()));
        return false;
    }

    // Store current file index for later access
    m_currentFileIndex = fileIndex;

    return true;
}

std::shared_ptr<ChannelData> DataController::getChannelData(int fileIndex, int channelIndex) {
    if (!m_metadata) {
        return nullptr;
    }

    const auto& files = m_metadata->getFiles();
    if (fileIndex < 0 || fileIndex >= static_cast<int>(files.size())) {
        return nullptr;
    }

    const auto& channels = files[fileIndex]->getChannels();
    if (channelIndex < 0 || channelIndex >= static_cast<int>(channels.size())) {
        return nullptr;
    }

    return channels[channelIndex];
}

bool DataController::loadChannelToFilter(int fileIndex, int channelIndex) {
    if (!m_filterController) {
        std::cerr << "Filter controller not set!" << std::endl;
        emit errorOccurred("Filter controller not initialized");
        return false;
    }

    auto channel = getChannelData(fileIndex, channelIndex);
    if (!channel) {
        emit errorOccurred("Failed to get channel data");
        return false;
    }

    // Check if binary data is loaded
    if (channel->getData().empty()) {
        std::cerr << "Channel data is empty. Loading binary data..." << std::endl;
        if (!loadBinaryData(fileIndex)) {
            return false;
        }
        channel = getChannelData(fileIndex, channelIndex);
        if (!channel || channel->getData().empty()) {
            emit errorOccurred("Failed to load channel binary data");
            return false;
        }
    }

    // Set channel data in filter controller
    m_filterController->setChannelData(channel);

    std::cout << "Loaded channel " << channelIndex << " from file " << fileIndex
              << " into filter controller (" << channel->getData().size() << " samples)" << std::endl;

    return true;
}

QString DataController::getFileName(int index) {
    if (!m_metadata) {
        return "";
    }

    const auto& files = m_metadata->getFiles();
    if (index < 0 || index >= static_cast<int>(files.size())) {
        return "";
    }

    return QString::fromStdString(files[index]->getSourceFile());
}

int DataController::getChannelCount(int fileIndex) {
    if (!m_metadata) {
        return 0;
    }

    const auto& files = m_metadata->getFiles();
    if (fileIndex < 0 || fileIndex >= static_cast<int>(files.size())) {
        return 0;
    }

    return files[fileIndex]->getNumChannels();
}

QString DataController::getChannelName(int fileIndex, int channelIndex) {
    if (!m_metadata) {
        return "";
    }

    const auto& files = m_metadata->getFiles();
    if (fileIndex < 0 || fileIndex >= static_cast<int>(files.size())) {
        return "";
    }

    const auto& channels = files[fileIndex]->getChannels();
    if (channelIndex < 0 || channelIndex >= static_cast<int>(channels.size())) {
        return "";
    }

    return QString::fromStdString(channels[channelIndex]->getName());
}

void DataController::updateFileList() {
    m_fileList.clear();

    if (!m_metadata) {
        emit fileListChanged();
        return;
    }

    for (const auto& file : m_metadata->getFiles()) {
        m_fileList.append(QString::fromStdString(file->getSourceFile()));
    }

    emit fileListChanged();
}
