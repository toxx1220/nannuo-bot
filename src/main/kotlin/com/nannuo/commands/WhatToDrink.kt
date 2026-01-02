package com.nannuo.commands

import com.nannuo.domain.TeaCategory
import com.nannuo.domain.TeaRepository
import com.nannuo.domain.TeaSubCategory
import dev.kord.core.entity.Message
import kotlin.jvm.optionals.getOrNull

private val USAGE_ADVICE = """
    Usage: `!whattodrink [optional: mainCategory] [optional: subCategory]`
    Available categories: %s
""".trimIndent()

/**
 * !whattodrink [optional: mainCategory] [optional: subcategory]
 * Examples:
 * !whattodrink
 * !whattodrink green
 * !whattodrink chinese
 * !whattodrink green chinese -> seems most consistent
 */

class WhatToDrink : Command {
    override val name: String = "whattodrink"
    override val description: String = "Suggests a random tea for you."

    override suspend fun execute(
        message: Message,
        args: List<String>,
    ) {
        when (args.size) {
            0 -> sendRecommendation(message, TeaRepository.getRandomTea().name)

            1 -> {
                val category: TeaCategory = TeaCategory.fromString(args[0]).getOrNull()
                    ?: return sendUsageAdvice(message, "Invalid tea category: ${args[0]}")

                sendRecommendation(message, TeaRepository.getRandomTeaWith(category).name)
            }

            2 -> {
                val category: TeaCategory = TeaCategory.fromString(args[0]).getOrNull()
                    ?: return sendUsageAdvice(message, "Invalid tea category: ${args[0]}")
                val subCategory: TeaSubCategory = TeaSubCategory.fromString(args[1]).getOrNull()
                    ?: return sendUsageAdvice(message, "Invalid tea subcategory: ${args[1]}")

                sendRecommendation(message, TeaRepository.getRandomTeaWith(category, subCategory).name)
            }

            else -> sendUsageAdvice(message, "Invalid number of arguments.")
        }
    }

    private fun getCategory(arg: String): TeaCategory = (TeaCategory.fromString(arg).getOrNull()
        ?: throw IllegalArgumentException("Invalid tea category: $arg"))

    private suspend fun sendRecommendation(message: Message, teaName: String) {
        val suggestion = MessageVariations.suggestions.random().format(teaName)
        message.channel.createMessage(suggestion)
    }

    private suspend fun sendUsageAdvice(msg: Message, error: String?) {
        val errorString = error?.let { "$it\n" } ?: ""
        val allCategories = getCategoryOptions().joinToString("")

        msg.channel.createMessage(
            errorString + USAGE_ADVICE.format(allCategories),
        )
    }

    private fun getCategoryOptions(): List<String> {
        return TeaCategory.entries
            .map { mainCategory ->
                val mainCategoryName = mainCategory.name.capitalizeFirstLowerRest()
                val subCategoryNames =
                    TeaSubCategory.getByMainCategory(mainCategory).map { it.name.capitalizeFirstLowerRest() }
                val subCategoryString =
                    if (subCategoryNames.isEmpty()) {
                        "no subcategories available"
                    } else {
                        subCategoryNames.joinToString(", ")
                    }
                return@map "\n$mainCategoryName: *[$subCategoryString]*"
            }.toList()
    }

    private fun getMainCategoryOptions(): List<String> {
        return TeaCategory.entries.map { it.name.capitalizeFirstLowerRest() }
    }

    private fun String.capitalizeFirstLowerRest(): String =
        lowercase().replaceFirstChar { it.titlecase() }


    object MessageVariations {
        val suggestions = listOf(
            "How about trying some %s today?",
            "I recommend you drink %s!",
            "Why not enjoy a cup of %s?",
            "You should try %s!",
            "A perfect choice would be %s.",
        )
    }
}
