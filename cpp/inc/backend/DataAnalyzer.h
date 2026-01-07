#ifndef DATAANALYZER_H
#define DATAANALYZER_H

#include <vector>
#include <memory>
#include "ChannelData.h"

/**
 * @brief Analyzes ACQ signal data and extracts features
 */
class DataAnalyzer {
public:
    DataAnalyzer();
    ~DataAnalyzer();

    /**
     * @brief Calculate basic statistics for a signal
     */
    struct Statistics {
        float min;
        float max;
        float mean;
        float std;
        float rms;
        float median;
    };

    /**
     * @brief Calculate statistics for signal data
     * @param data Input signal data
     * @return Statistics structure
     */
    Statistics calculateStatistics(const std::vector<float>& data);

    /**
     * @brief Calculate power spectrum density (simplified)
     * @param data Input signal data
     * @param sampleRate Sample rate in Hz
     * @return Vector of power values
     */
    std::vector<float> calculatePSD(const std::vector<float>& data, float sampleRate);

    /**
     * @brief Detect signal activity periods
     * @param data Input signal data
     * @param threshold Activity threshold
     * @return Vector of (start, end) index pairs
     */
    std::vector<std::pair<size_t, size_t>> detectActivity(
        const std::vector<float>& data, float threshold);

    /**
     * @brief Calculate zero crossing rate
     * @param data Input signal data
     * @return Zero crossing rate
     */
    float calculateZeroCrossingRate(const std::vector<float>& data);

private:
    float median(std::vector<float> data);  // Note: takes copy for sorting
};

#endif // DATAANALYZER_H
