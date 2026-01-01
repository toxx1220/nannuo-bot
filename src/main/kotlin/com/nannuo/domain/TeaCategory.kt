package com.nannuo.domain

enum class TeaCategory(val displayName: String) { // TODO: displayName vs command/categoryName
    WHITE("White"),
    GREEN_CHINESE("Chinese Green"), // todo: args for command processing
    GREEN_JAPANESE("Japanese Green"),
    YELLOW("Yellow"),
    OOLONG_ANXI("Anxi Oolong"),
    OOLONG_TAIWANESE("Taiwanese Oolong"),
    OOLONG_YANCHA("Yancha Oolong"),
    OOLONG_DANCONG("Dancong Oolong"),
    BLACK("Black"),
    PUER_FACTORY("Factory Puer"),
    PUER_BOUTIQUE("Boutique Puer"),
    NON_PU_HEICHA("Non-Pu Heicha"),
}
