#ifndef ACQMETADATA_H
#define ACQMETADATA_H

#include "ChannelData.h"
#include <string>
#include <vector>
#include <memory>

/**
 * @brief Represents metadata for a single ACQ file
 */
class ACQFileMetadata {
public:
    ACQFileMetadata();
    ~ACQFileMetadata();

    std::string getSourceFile() const { return sourceFile; }
    std::string getTimestamp() const { return processedTimestamp; }
    int getNumChannels() const { return numChannels; }

    void setSourceFile(const std::string& file) { sourceFile = file; }
    void setTimestamp(const std::string& ts) { processedTimestamp = ts; }
    void setNumChannels(int num) { numChannels = num; }

    void addChannel(std::shared_ptr<ChannelData> channel);
    const std::vector<std::shared_ptr<ChannelData>>& getChannels() const { return channels; }

private:
    std::string sourceFile;
    std::string processedTimestamp;
    int numChannels;
    std::vector<std::shared_ptr<ChannelData>> channels;
};

/**
 * @brief Represents the complete metadata.json containing all ACQ files
 */
class ACQMetadata {
public:
    ACQMetadata();
    ~ACQMetadata();

    std::string getCreated() const { return created; }
    std::string getLastUpdated() const { return lastUpdated; }
    int getTotalFilesProcessed() const { return totalFilesProcessed; }

    void setCreated(const std::string& ts) { created = ts; }
    void setLastUpdated(const std::string& ts) { lastUpdated = ts; }
    void setTotalFilesProcessed(int count) { totalFilesProcessed = count; }

    void addFile(std::shared_ptr<ACQFileMetadata> file);
    const std::vector<std::shared_ptr<ACQFileMetadata>>& getFiles() const { return files; }

private:
    std::string created;
    std::string lastUpdated;
    int totalFilesProcessed;
    std::vector<std::shared_ptr<ACQFileMetadata>> files;
};

#endif // ACQMETADATA_H
