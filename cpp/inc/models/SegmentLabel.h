#ifndef SEGMENTLABEL_H
#define SEGMENTLABEL_H

#include <string>
#include <vector>

/**
 * @brief Represents a labeled segment in the waveform
 */
class SegmentLabel {
public:
    SegmentLabel();
    SegmentLabel(size_t start, size_t end, const std::string& label, const std::string& color);
    ~SegmentLabel();

    // Getters
    size_t getStartIndex() const { return startIndex; }
    size_t getEndIndex() const { return endIndex; }
    std::string getLabel() const { return label; }
    std::string getColor() const { return color; }
    int getId() const { return id; }
    float getStartTime() const { return startTime; }
    float getEndTime() const { return endTime; }
    const std::vector<float>& getVoltageData() const { return voltageData; }

    // Setters
    void setStartIndex(size_t start) { startIndex = start; }
    void setEndIndex(size_t end) { endIndex = end; }
    void setLabel(const std::string& lbl) { label = lbl; }
    void setColor(const std::string& col) { color = col; }
    void setStartTime(float time) { startTime = time; }
    void setEndTime(float time) { endTime = time; }
    void setVoltageData(const std::vector<float>& data) { voltageData = data; }

    // Utility
    size_t getLength() const { return endIndex - startIndex; }
    bool contains(size_t index) const { return index >= startIndex && index <= endIndex; }
    bool overlaps(size_t start, size_t end) const;

private:
    int id;
    size_t startIndex;
    size_t endIndex;
    std::string label;
    std::string color;  // Hex color code like "#FF0000"
    float startTime;    // Start time in seconds
    float endTime;      // End time in seconds
    std::vector<float> voltageData;  // Voltage values in the segment

    static int nextId;
};

#endif // SEGMENTLABEL_H
