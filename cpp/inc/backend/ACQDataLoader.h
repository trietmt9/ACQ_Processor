#ifndef ACQDATALOADER_H
#define ACQDATALOADER_H

#include <string>
#include <memory>
#include "ACQMetadata.h"

/**
 * @brief Loads ACQ data from JSON metadata and binary files
 */
class ACQDataLoader {
public:
    ACQDataLoader();
    ~ACQDataLoader();

    /**
     * @brief Load metadata from JSON file
     * @param jsonFilePath Path to metadata.json
     * @return Shared pointer to ACQMetadata object
     */
    std::shared_ptr<ACQMetadata> loadMetadata(const std::string& jsonFilePath);

    /**
     * @brief Load binary data for all channels in a file
     * @param fileMetadata File metadata containing channel information
     * @param dataDirectory Directory containing binary files
     * @return True if successful
     */
    bool loadBinaryData(std::shared_ptr<ACQFileMetadata> fileMetadata,
                       const std::string& dataDirectory);

    /**
     * @brief Load binary data for a single channel
     * @param channel Channel to load data for
     * @param dataDirectory Directory containing binary files
     * @return True if successful
     */
    bool loadChannelData(std::shared_ptr<ChannelData> channel,
                        const std::string& dataDirectory);

    std::string getLastError() const { return lastError; }

private:
    std::string lastError;
};

#endif // ACQDATALOADER_H
