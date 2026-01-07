#include "LabelManager.h"
#include "json.hpp"
#include <fstream>
#include <iostream>
#include <algorithm>
#include <numeric>

using json = nlohmann::json;

LabelManager::LabelManager(QObject *parent)
    : QObject(parent)
    , m_sampleRate(1000.0f)
{
}

LabelManager::~LabelManager() {
}

int LabelManager::addLabel(int startIndex, int endIndex, const QString& labelText, const QString& color) {
    if (startIndex >= endIndex) {
        std::cerr << "Invalid label range: start >= end" << std::endl;
        return -1;
    }

    auto label = std::make_shared<SegmentLabel>(
        startIndex,
        endIndex,
        labelText.toStdString(),
        color.toStdString()
    );

    // Calculate time information
    if (m_sampleRate > 0) {
        float startTime = static_cast<float>(startIndex) / m_sampleRate;
        float endTime = static_cast<float>(endIndex) / m_sampleRate;
        label->setStartTime(startTime);
        label->setEndTime(endTime);
    }

    // Extract voltage data for this segment
    std::cout << "Extracting voltage data for label..." << std::endl;
    std::cout << "  Total voltage data size: " << m_voltageData.size() << std::endl;
    std::cout << "  Requested range: [" << startIndex << ", " << endIndex << ")" << std::endl;

    if (!m_voltageData.empty() && startIndex < m_voltageData.size() && endIndex <= m_voltageData.size()) {
        std::vector<float> segmentVoltages(
            m_voltageData.begin() + startIndex,
            m_voltageData.begin() + endIndex
        );
        label->setVoltageData(segmentVoltages);

        std::cout << "  ✓ Extracted " << segmentVoltages.size() << " voltage samples" << std::endl;
        if (!segmentVoltages.empty()) {
            float minV = *std::min_element(segmentVoltages.begin(), segmentVoltages.end());
            float maxV = *std::max_element(segmentVoltages.begin(), segmentVoltages.end());
            std::cout << "  ✓ Voltage range: [" << minV << ", " << maxV << "] mV" << std::endl;
        }
    } else {
        std::cerr << "  ✗ WARNING: Cannot extract voltage data!" << std::endl;
        std::cerr << "    Voltage data empty: " << m_voltageData.empty() << std::endl;
        std::cerr << "    Start index valid: " << (startIndex < m_voltageData.size()) << std::endl;
        std::cerr << "    End index valid: " << (endIndex <= m_voltageData.size()) << std::endl;
    }

    m_labels.push_back(label);

    emit labelCountChanged();
    emit labelsChanged();
    emit labelAdded(label->getId());

    std::cout << "Added label: " << labelText.toStdString()
              << " (" << startIndex << "-" << endIndex << ") "
              << "color: " << color.toStdString() << std::endl;

    return label->getId();
}

bool LabelManager::removeLabel(int labelId) {
    auto it = std::remove_if(m_labels.begin(), m_labels.end(),
                            [labelId](const std::shared_ptr<SegmentLabel>& label) {
                                return label->getId() == labelId;
                            });

    if (it != m_labels.end()) {
        m_labels.erase(it, m_labels.end());

        emit labelCountChanged();
        emit labelsChanged();
        emit labelRemoved(labelId);

        std::cout << "Removed label ID: " << labelId << std::endl;
        return true;
    }

    return false;
}

bool LabelManager::updateLabel(int labelId, int startIndex, int endIndex, const QString& labelText, const QString& color) {
    auto label = findLabelById(labelId);
    if (!label) {
        return false;
    }

    label->setStartIndex(startIndex);
    label->setEndIndex(endIndex);
    label->setLabel(labelText.toStdString());
    label->setColor(color.toStdString());

    emit labelsChanged();
    emit labelUpdated(labelId);

    return true;
}

void LabelManager::clearLabels() {
    m_labels.clear();

    emit labelCountChanged();
    emit labelsChanged();

    std::cout << "Cleared all labels" << std::endl;
}

QVariantMap LabelManager::getLabelAt(int sampleIndex) {
    for (const auto& label : m_labels) {
        if (label->contains(sampleIndex)) {
            QVariantMap map;
            map["id"] = label->getId();
            map["startIndex"] = static_cast<int>(label->getStartIndex());
            map["endIndex"] = static_cast<int>(label->getEndIndex());
            map["label"] = QString::fromStdString(label->getLabel());
            map["color"] = QString::fromStdString(label->getColor());
            return map;
        }
    }

    return QVariantMap();  // Empty map if not found
}

QVariantList LabelManager::getLabelsAsVariant() const {
    QVariantList result;

    for (const auto& label : m_labels) {
        QVariantMap map;
        map["id"] = label->getId();
        map["startIndex"] = static_cast<int>(label->getStartIndex());
        map["endIndex"] = static_cast<int>(label->getEndIndex());
        map["label"] = QString::fromStdString(label->getLabel());
        map["color"] = QString::fromStdString(label->getColor());
        result.append(map);
    }

    return result;
}

bool LabelManager::saveToFile(const QString& filePath) {
    std::cout << "\n========================================" << std::endl;
    std::cout << "SAVING LABELS TO FILE" << std::endl;
    std::cout << "========================================" << std::endl;
    std::cout << "File path: " << filePath.toStdString() << std::endl;
    std::cout << "Number of labels: " << m_labels.size() << std::endl;

    if (m_labels.empty()) {
        std::cerr << "WARNING: No labels to save!" << std::endl;
        return false;
    }

    json j;
    j["labels"] = json::array();

    int labelIndex = 0;
    for (const auto& label : m_labels) {
        std::cout << "\nLabel #" << (labelIndex + 1) << ":" << std::endl;
        std::cout << "  Name: " << label->getLabel() << std::endl;
        std::cout << "  Indices: " << label->getStartIndex() << " - " << label->getEndIndex() << std::endl;
        std::cout << "  Time: " << label->getStartTime() << "s - " << label->getEndTime() << "s" << std::endl;
        std::cout << "  Color: " << label->getColor() << std::endl;

        json labelJson;
        labelJson["start_index"] = label->getStartIndex();
        labelJson["end_index"] = label->getEndIndex();
        labelJson["start_time"] = label->getStartTime();
        labelJson["end_time"] = label->getEndTime();
        labelJson["label"] = label->getLabel();
        labelJson["color"] = label->getColor();

        // Add voltage data
        const auto& voltages = label->getVoltageData();
        labelJson["voltage_data"] = voltages;

        std::cout << "  Voltage samples: " << voltages.size() << std::endl;

        // Calculate voltage statistics
        if (!voltages.empty()) {
            float minVoltage = *std::min_element(voltages.begin(), voltages.end());
            float maxVoltage = *std::max_element(voltages.begin(), voltages.end());
            float avgVoltage = std::accumulate(voltages.begin(), voltages.end(), 0.0f) / voltages.size();

            labelJson["voltage_min"] = minVoltage;
            labelJson["voltage_max"] = maxVoltage;
            labelJson["voltage_avg"] = avgVoltage;

            std::cout << "  Voltage range: [" << minVoltage << ", " << maxVoltage << "] mV" << std::endl;
            std::cout << "  Voltage avg: " << avgVoltage << " mV" << std::endl;
        }

        j["labels"].push_back(labelJson);
        labelIndex++;
    }

    try {
        std::cout << "Opening file for writing: " << filePath.toStdString() << std::endl;

        std::ofstream file(filePath.toStdString());
        if (!file.is_open()) {
            std::cerr << "ERROR: Failed to open file for writing: " << filePath.toStdString() << std::endl;
            return false;
        }

        std::string jsonStr = j.dump(2);  // Pretty print with 2-space indent
        std::cout << "Writing " << jsonStr.length() << " bytes to file..." << std::endl;

        file << jsonStr;
        file.close();

        if (file.fail()) {
            std::cerr << "ERROR: Failed to write to file: " << filePath.toStdString() << std::endl;
            return false;
        }

        std::cout << "\n✓ SUCCESS!" << std::endl;
        std::cout << "✓ Saved " << m_labels.size() << " labels to: " << filePath.toStdString() << std::endl;
        std::cout << "✓ File size: " << jsonStr.length() << " bytes" << std::endl;
        std::cout << "========================================\n" << std::endl;
        return true;
    } catch (const std::exception& e) {
        std::cerr << "✗ Exception while saving labels: " << e.what() << std::endl;
        return false;
    }
}

bool LabelManager::loadFromFile(const QString& filePath) {
    try {
        std::ifstream file(filePath.toStdString());
        if (!file.is_open()) {
            std::cerr << "Failed to open file: " << filePath.toStdString() << std::endl;
            return false;
        }

        json j;
        file >> j;

        clearLabels();

        if (j.contains("labels") && j["labels"].is_array()) {
            for (const auto& labelJson : j["labels"]) {
                size_t start = labelJson["start_index"];
                size_t end = labelJson["end_index"];
                std::string label = labelJson["label"];
                std::string color = labelJson["color"];

                addLabel(start, end, QString::fromStdString(label), QString::fromStdString(color));
            }
        }

        std::cout << "Loaded " << m_labels.size() << " labels from " << filePath.toStdString() << std::endl;
        return true;
    } catch (const std::exception& e) {
        std::cerr << "Failed to load labels: " << e.what() << std::endl;
        return false;
    }
}

std::shared_ptr<SegmentLabel> LabelManager::findLabelById(int id) {
    auto it = std::find_if(m_labels.begin(), m_labels.end(),
                          [id](const std::shared_ptr<SegmentLabel>& label) {
                              return label->getId() == id;
                          });

    if (it != m_labels.end()) {
        return *it;
    }

    return nullptr;
}
