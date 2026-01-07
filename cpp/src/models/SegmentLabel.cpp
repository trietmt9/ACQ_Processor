#include "SegmentLabel.h"

int SegmentLabel::nextId = 0;

SegmentLabel::SegmentLabel()
    : id(nextId++)
    , startIndex(0)
    , endIndex(0)
    , label("")
    , color("#FF0000")
    , startTime(0.0f)
    , endTime(0.0f)
{
}

SegmentLabel::SegmentLabel(size_t start, size_t end, const std::string& lbl, const std::string& col)
    : id(nextId++)
    , startIndex(start)
    , endIndex(end)
    , label(lbl)
    , color(col)
    , startTime(0.0f)
    , endTime(0.0f)
{
}

SegmentLabel::~SegmentLabel() {
}

bool SegmentLabel::overlaps(size_t start, size_t end) const {
    return !(end < startIndex || start > endIndex);
}
