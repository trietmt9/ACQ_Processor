#include "ChartController.h"
#include <QPointF>
#include <algorithm>

ChartController::ChartController(QObject *parent)
    : QObject(parent)
    , m_hasData(false)
    , m_dataSize(0)
{
}

ChartController::~ChartController() {
}

void ChartController::setData(std::shared_ptr<ChannelData> channel) {
    m_channelData = channel;

    if (m_channelData && !m_channelData->getData().empty()) {
        m_hasData = true;
        m_dataSize = m_channelData->getData().size();
    } else {
        m_hasData = false;
        m_dataSize = 0;
    }

    emit hasDataChanged();
    emit dataSizeChanged();
}

void ChartController::clearData() {
    m_channelData.reset();
    m_hasData = false;
    m_dataSize = 0;

    emit hasDataChanged();
    emit dataSizeChanged();
}

QVariantList ChartController::getChartData(int maxPoints) {
    QVariantList result;

    if (!m_channelData || m_channelData->getData().empty()) {
        return result;
    }

    const auto& data = m_channelData->getData();

    if (static_cast<int>(data.size()) <= maxPoints) {
        // Return all points
        for (size_t i = 0; i < data.size(); ++i) {
            result.append(QPointF(i, data[i]));
        }
    } else {
        // Downsample
        return getDownsampledData(maxPoints);
    }

    return result;
}

QVariantList ChartController::getDownsampledData(int targetPoints) {
    if (!m_channelData || m_channelData->getData().empty()) {
        return QVariantList();
    }

    return downsampleData(m_channelData->getData(), targetPoints);
}

QVariantList ChartController::downsampleData(const std::vector<float>& data, int targetPoints) {
    QVariantList result;

    if (data.empty() || targetPoints <= 0) {
        return result;
    }

    if (static_cast<int>(data.size()) <= targetPoints) {
        // No downsampling needed
        for (size_t i = 0; i < data.size(); ++i) {
            result.append(QPointF(i, data[i]));
        }
        return result;
    }

    // Simple decimation: take every nth point
    int step = data.size() / targetPoints;

    for (size_t i = 0; i < data.size(); i += step) {
        result.append(QPointF(i, data[i]));
    }

    // Always include last point
    if (result.size() > 0) {
        QPointF lastPoint = result.last().toPointF();
        if (static_cast<size_t>(lastPoint.x()) != data.size() - 1) {
            result.append(QPointF(data.size() - 1, data.back()));
        }
    }

    return result;
}

void ChartController::setChannelData(int fileIndex, int channelIndex) {
    // This method would be implemented when integrated with DataController
    // For now, it's a placeholder
    Q_UNUSED(fileIndex);
    Q_UNUSED(channelIndex);
}
