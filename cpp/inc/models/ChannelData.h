#ifndef CHANNELDATA_H
#define CHANNELDATA_H

#include <string>
#include <vector>

/**
 * @brief Represents a single channel's data from an ACQ file
 */
class ChannelData {
public:
    ChannelData();
    ~ChannelData();

    // Getters
    int getIndex() const { return index; }
    std::string getName() const { return name; }
    std::string getUnits() const { return units; }
    float getSampleRate() const { return sampleRate; }
    size_t getNumSamples() const { return numSamples; }
    float getDuration() const { return duration; }
    std::string getBinaryFile() const { return binaryFile; }

    const std::vector<float>& getData() const { return data; }

    // Statistics
    float getMin() const { return min; }
    float getMax() const { return max; }
    float getMean() const { return mean; }
    float getStd() const { return std; }

    // Setters
    void setIndex(int idx) { index = idx; }
    void setName(const std::string& n) { name = n; }
    void setUnits(const std::string& u) { units = u; }
    void setSampleRate(float rate) { sampleRate = rate; }
    void setNumSamples(size_t num) { numSamples = num; }
    void setDuration(float dur) { duration = dur; }
    void setBinaryFile(const std::string& file) { binaryFile = file; }
    void setStatistics(float minVal, float maxVal, float meanVal, float stdVal);

    // Data loading
    bool loadBinaryData(const std::string& filepath);
    void setData(const std::vector<float>& newData);

private:
    int index;
    std::string name;
    std::string units;
    float sampleRate;
    size_t numSamples;
    float duration;
    std::string binaryFile;

    std::vector<float> data;

    // Statistics
    float min;
    float max;
    float mean;
    float std;
};

#endif // CHANNELDATA_H
