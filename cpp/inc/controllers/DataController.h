#ifndef DATACONTROLLER_H
#define DATACONTROLLER_H

#include <QObject>
#include <QString>
#include <QStringList>
#include <memory>
#include "ACQMetadata.h"
#include "ACQDataLoader.h"

// Forward declaration
class FilterController;

/**
 * @brief Controller for managing ACQ data (QML-C++ bridge)
 */
class DataController : public QObject {
    Q_OBJECT

    Q_PROPERTY(QString metadataPath READ metadataPath WRITE setMetadataPath NOTIFY metadataPathChanged)
    Q_PROPERTY(int totalFiles READ totalFiles NOTIFY totalFilesChanged)
    Q_PROPERTY(bool dataLoaded READ dataLoaded NOTIFY dataLoadedChanged)
    Q_PROPERTY(QStringList fileList READ fileList NOTIFY fileListChanged)

public:
    explicit DataController(QObject *parent = nullptr);
    ~DataController();

    // Set filter controller reference
    void setFilterController(FilterController* filterCtrl) { m_filterController = filterCtrl; }

    // Property getters
    QString metadataPath() const { return m_metadataPath; }
    int totalFiles() const { return m_totalFiles; }
    bool dataLoaded() const { return m_dataLoaded; }
    QStringList fileList() const { return m_fileList; }

    // Property setters
    void setMetadataPath(const QString &path);

    // Invokable methods (callable from QML)
    Q_INVOKABLE bool loadMetadata();
    Q_INVOKABLE bool loadBinaryData(int fileIndex);
    Q_INVOKABLE bool loadChannelToFilter(int fileIndex, int channelIndex);
    Q_INVOKABLE QString getFileName(int index);
    Q_INVOKABLE int getChannelCount(int fileIndex);
    Q_INVOKABLE QString getChannelName(int fileIndex, int channelIndex);

    // Get underlying data
    std::shared_ptr<ACQMetadata> getMetadata() const { return m_metadata; }
    std::shared_ptr<ChannelData> getChannelData(int fileIndex, int channelIndex);

signals:
    void metadataPathChanged();
    void totalFilesChanged();
    void dataLoadedChanged();
    void fileListChanged();
    void loadingProgress(int current, int total);
    void errorOccurred(const QString &error);

private:
    QString m_metadataPath;
    int m_totalFiles;
    bool m_dataLoaded;
    QStringList m_fileList;
    int m_currentFileIndex;

    std::shared_ptr<ACQMetadata> m_metadata;
    ACQDataLoader m_loader;
    FilterController* m_filterController;

    void updateFileList();
};

#endif // DATACONTROLLER_H
