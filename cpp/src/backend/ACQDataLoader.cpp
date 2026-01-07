#include "ACQDataLoader.h"
#include "json.hpp"
#include <fstream>
#include <iostream>

using json = nlohmann::json;

ACQDataLoader::ACQDataLoader() {
}

ACQDataLoader::~ACQDataLoader() {
}

std::shared_ptr<ACQMetadata> ACQDataLoader::loadMetadata(const std::string& jsonFilePath) {
    std::ifstream file(jsonFilePath);

    if (!file.is_open()) {
        lastError = "Failed to open JSON file: " + jsonFilePath;
        std::cerr << lastError << std::endl;
        return nullptr;
    }

    json j;
    try {
        file >> j;
    } catch (const json::parse_error& e) {
        lastError = "JSON parse error: " + std::string(e.what());
        std::cerr << lastError << std::endl;
        return nullptr;
    }

    auto metadata = std::make_shared<ACQMetadata>();

    // Parse top-level metadata
    if (j.contains("created")) {
        metadata->setCreated(j["created"].get<std::string>());
    }
    if (j.contains("last_updated")) {
        metadata->setLastUpdated(j["last_updated"].get<std::string>());
    }
    if (j.contains("total_files_processed")) {
        metadata->setTotalFilesProcessed(j["total_files_processed"].get<int>());
    }

    // Parse files array
    if (j.contains("files") && j["files"].is_array()) {
        for (const auto& fileJson : j["files"]) {
            auto fileMetadata = std::make_shared<ACQFileMetadata>();

            if (fileJson.contains("source_file")) {
                fileMetadata->setSourceFile(fileJson["source_file"].get<std::string>());
            }
            if (fileJson.contains("processed_timestamp")) {
                fileMetadata->setTimestamp(fileJson["processed_timestamp"].get<std::string>());
            }
            if (fileJson.contains("num_channels")) {
                fileMetadata->setNumChannels(fileJson["num_channels"].get<int>());
            }

            // Parse channels array
            if (fileJson.contains("channels") && fileJson["channels"].is_array()) {
                for (const auto& channelJson : fileJson["channels"]) {
                    auto channel = std::make_shared<ChannelData>();

                    channel->setIndex(channelJson["index"].get<int>());
                    channel->setName(channelJson["name"].get<std::string>());
                    channel->setUnits(channelJson["units"].get<std::string>());
                    channel->setSampleRate(channelJson["sample_rate"].get<float>());
                    channel->setNumSamples(channelJson["num_samples"].get<size_t>());
                    channel->setDuration(channelJson["duration_seconds"].get<float>());
                    channel->setBinaryFile(channelJson["binary_file"].get<std::string>());

                    if (channelJson.contains("statistics")) {
                        const auto& stats = channelJson["statistics"];
                        channel->setStatistics(
                            stats["min"].get<float>(),
                            stats["max"].get<float>(),
                            stats["mean"].get<float>(),
                            stats["std"].get<float>()
                        );
                    }

                    fileMetadata->addChannel(channel);
                }
            }

            metadata->addFile(fileMetadata);
        }
    }

    std::cout << "Successfully loaded metadata: " << metadata->getTotalFilesProcessed()
              << " files" << std::endl;

    return metadata;
}

bool ACQDataLoader::loadBinaryData(std::shared_ptr<ACQFileMetadata> fileMetadata,
                                   const std::string& dataDirectory) {
    if (!fileMetadata) {
        lastError = "Invalid file metadata";
        return false;
    }

    for (const auto& channel : fileMetadata->getChannels()) {
        if (!loadChannelData(channel, dataDirectory)) {
            return false;
        }
    }

    return true;
}

bool ACQDataLoader::loadChannelData(std::shared_ptr<ChannelData> channel,
                                   const std::string& dataDirectory) {
    if (!channel) {
        lastError = "Invalid channel";
        return false;
    }

    std::string filepath = dataDirectory + "/" + channel->getBinaryFile();
    return channel->loadBinaryData(filepath);
}
