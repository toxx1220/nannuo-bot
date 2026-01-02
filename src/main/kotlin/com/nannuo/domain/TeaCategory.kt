package com.nannuo.domain

import java.util.*

enum class TeaCategory {
    WHITE,
    GREEN,
    YELLOW,
    OOLONG,
    BLACK,
    PUER,
    HEICHA;

    companion object {
        fun fromString(value: String): Optional<TeaCategory> {
            return Optional.ofNullable(entries.find { it.name.equals(value, ignoreCase = true) })
        }
    }
}

enum class TeaSubCategory(val mainCategory: TeaCategory) {
    CHINESE(TeaCategory.GREEN),
    JAPANESE(TeaCategory.GREEN),
    ANXI(TeaCategory.OOLONG),
    TAIWANESE(TeaCategory.OOLONG),
    YANCHA(TeaCategory.OOLONG),
    DANCONG(TeaCategory.OOLONG),
    FACTORY(TeaCategory.PUER),
    BOUTIQUE(TeaCategory.PUER);

    companion object {
        fun fromString(value: String): Optional<TeaSubCategory> {
            return Optional.ofNullable(entries.find { it.name.equals(value, ignoreCase = true) })
        }

        fun getByMainCategory(category: TeaCategory): List<TeaSubCategory> {
            return entries.filter { it.mainCategory == category }
        }
    }
}
