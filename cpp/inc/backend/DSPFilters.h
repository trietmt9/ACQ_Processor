#ifndef DSPFILTERS_H
#define DSPFILTERS_H

#include <vector>
#include <complex>
#include <string>

/**
 * @brief Digital Signal Processing Filters
 *
 * Implements common IIR (Infinite Impulse Response) Butterworth filters:
 * - Lowpass: Passes frequencies below cutoff
 * - Highpass: Passes frequencies above cutoff
 * - Bandpass: Passes frequencies between two cutoffs
 * - Notch (Band-stop): Rejects frequencies between two cutoffs
 */
class DSPFilters {
public:
    DSPFilters();
    ~DSPFilters();

    /**
     * @brief Filter types
     */
    enum FilterType {
        LOWPASS,
        HIGHPASS,
        BANDPASS,
        NOTCH
    };

    /**
     * @brief Apply lowpass filter
     * @param data Input signal
     * @param sampleRate Sample rate in Hz
     * @param cutoffFreq Cutoff frequency in Hz
     * @param order Filter order (default: 4)
     * @return Filtered signal
     */
    std::vector<float> lowpass(const std::vector<float>& data,
                               float sampleRate,
                               float cutoffFreq,
                               int order = 4);

    /**
     * @brief Apply highpass filter
     * @param data Input signal
     * @param sampleRate Sample rate in Hz
     * @param cutoffFreq Cutoff frequency in Hz
     * @param order Filter order (default: 4)
     * @return Filtered signal
     */
    std::vector<float> highpass(const std::vector<float>& data,
                               float sampleRate,
                               float cutoffFreq,
                               int order = 4);

    /**
     * @brief Apply bandpass filter
     * @param data Input signal
     * @param sampleRate Sample rate in Hz
     * @param lowCutoff Low cutoff frequency in Hz
     * @param highCutoff High cutoff frequency in Hz
     * @param order Filter order (default: 4)
     * @return Filtered signal
     */
    std::vector<float> bandpass(const std::vector<float>& data,
                               float sampleRate,
                               float lowCutoff,
                               float highCutoff,
                               int order = 4);

    /**
     * @brief Apply notch (band-stop) filter
     * @param data Input signal
     * @param sampleRate Sample rate in Hz
     * @param lowCutoff Low cutoff frequency in Hz
     * @param highCutoff High cutoff frequency in Hz
     * @param order Filter order (default: 4)
     * @return Filtered signal
     */
    std::vector<float> notch(const std::vector<float>& data,
                            float sampleRate,
                            float lowCutoff,
                            float highCutoff,
                            int order = 4);

    /**
     * @brief Generic filter application
     * @param data Input signal
     * @param sampleRate Sample rate in Hz
     * @param type Filter type
     * @param freq1 First frequency (cutoff or low cutoff)
     * @param freq2 Second frequency (only for bandpass/notch)
     * @param order Filter order
     * @return Filtered signal
     */
    std::vector<float> applyFilter(const std::vector<float>& data,
                                   float sampleRate,
                                   FilterType type,
                                   float freq1,
                                   float freq2 = 0.0f,
                                   int order = 4);

    /**
     * @brief Get last error message
     */
    std::string getLastError() const { return lastError; }

    /**
     * @brief Validate filter parameters
     */
    bool validateParameters(float sampleRate, float freq1, float freq2 = 0.0f);

private:
    std::string lastError;

    /**
     * @brief Butterworth filter coefficients structure
     */
    struct ButterworthCoeffs {
        std::vector<float> b;  // Numerator coefficients
        std::vector<float> a;  // Denominator coefficients
    };

    /**
     * @brief Design Butterworth lowpass filter coefficients
     */
    ButterworthCoeffs designLowpass(float sampleRate, float cutoffFreq, int order);

    /**
     * @brief Design Butterworth highpass filter coefficients
     */
    ButterworthCoeffs designHighpass(float sampleRate, float cutoffFreq, int order);

    /**
     * @brief Apply IIR filter using Direct Form II Transposed
     */
    std::vector<float> applyIIR(const std::vector<float>& data,
                               const ButterworthCoeffs& coeffs);

    /**
     * @brief Apply cascaded biquad sections for stability
     */
    std::vector<float> applyCascadedBiquads(const std::vector<float>& data,
                                           const std::vector<ButterworthCoeffs>& sections);

    /**
     * @brief Design second-order sections (biquads) for higher order filters
     */
    std::vector<ButterworthCoeffs> designBiquadSections(FilterType type,
                                                        float sampleRate,
                                                        float freq1,
                                                        float freq2,
                                                        int order);

    /**
     * @brief Compute bilinear transform
     */
    float bilinearTransform(float freq, float sampleRate);

    /**
     * @brief Prewarp frequency for bilinear transform
     */
    float prewarpFrequency(float freq, float sampleRate);
};

#endif // DSPFILTERS_H
