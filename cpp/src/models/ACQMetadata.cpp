#include "ACQMetadata.h"

// ACQFileMetadata implementation
ACQFileMetadata::ACQFileMetadata()
    : numChannels(0)
{
}

ACQFileMetadata::~ACQFileMetadata() {
}

void ACQFileMetadata::addChannel(std::shared_ptr<ChannelData> channel) {
    channels.push_back(channel);
}

// ACQMetadata implementation
ACQMetadata::ACQMetadata()
    : totalFilesProcessed(0)
{
}

ACQMetadata::~ACQMetadata() {
}

void ACQMetadata::addFile(std::shared_ptr<ACQFileMetadata> file) {
    files.push_back(file);
}
