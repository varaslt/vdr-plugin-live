/*
	This file has some own functionality and is used as backward
	compatibility for vdr prior to version 1.5.7 language support.
 */

#include "i18n.h"

namespace vdrlive {

I18n& LiveI18n()
{
    static I18n instance;
    return instance;
}

I18n::I18n()
  : m_encoding(
        cCharSetConv::SystemCharacterTable() ? cCharSetConv::SystemCharacterTable() : "UTF-8"
        )
{
    // fix encoding spelling for html standard.
    std::string const iso("iso");
    if (m_encoding.find(iso) != std::string::npos) {
        if (iso.length() == m_encoding.find_first_of("0123456789")) {
            m_encoding.insert(iso.length(), "-");
        }
    }
}

} // namespace vdrlive
