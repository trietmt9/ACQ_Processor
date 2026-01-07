#ifndef SIGNALPROCESSOR_H
#define SIGNALPROCESSOR_H

#include <vector>
#include <memory>
#include "ChannelData.h"
#include "DSPFilters.h"

/**
 * @brief Processes signal data (filtering, transformation, etc.)
 */
class SignalProcessor {
public:
    SignalProcessor();
    ~SignalProcessor();

    // Get DSP filters instance
    DSPFilters& getFilters() { return dspFilters; }

    /**
     * @brief Apply a simple moving average filter
     * @param data Input signal data
     * @param windowSize Window size for moving average
     * @return Filtered signal
     */
    std::vector<float> movingAverage(const std::vector<float>& data, int windowSize);

    /**
     * @brief Downsample signal by factor
     * @param data Input signal data
     * @param factor Downsampling factor
     * @return Downsampled signal
     */
    std::vector<float> downsample(const std::vector<float>& data, int factor);

    /**
     * @brief Calculate RMS (Root Mean Square) of signal
     * @param data Input signal data
     * @return RMS value
     */
    float calculateRMS(const std::vector<float>& data);

    /**
     * @brief Find peaks in signal above threshold
     * @param data Input signal data
     * @param threshold Minimum peak value
     * @return Vector of peak indices
     */
    std::vector<size_t> findPeaks(const std::vector<float>& data, float threshold);

    /**
     * @brief Normalize signal to range [0, 1]
     * @param data Input signal data
     * @return Normalized signal
     */
    std::vector<float> normalize(const std::vector<float>& data);

private:
    // Helper functions
    float mean(const std::vector<float>& data);
    float stdDev(const std::vector<float>& data);

    // DSP filters instance
    DSPFilters dspFilters;
};

#endif // SIGNALPROCESSOR_H
