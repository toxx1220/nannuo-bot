package com.nannuo.commands

import com.nannuo.domain.TeaCategory
import com.nannuo.domain.TeaRepository
import com.nannuo.domain.TeaSubCategory
import dev.kord.core.Kord
import dev.kord.core.behavior.interaction.response.DeferredPublicMessageInteractionResponseBehavior
import dev.kord.core.behavior.interaction.response.respond
import dev.kord.core.entity.interaction.ChatInputCommandInteraction
import dev.kord.core.entity.interaction.SubCommand
import dev.kord.rest.builder.interaction.string
import dev.kord.rest.builder.interaction.subCommand
import org.slf4j.Logger
import org.slf4j.LoggerFactory

private const val ANY_CATEGORY = "any"
private const val SUBCATEGORY = "subcategory"

class WhatToDrink : Command {
    override val name: String = "whattodrink"
    override val description: String = "Suggests a random tea for you."
    val logger: Logger = LoggerFactory.getLogger("WhatToDrink")

    override suspend fun register(kord: Kord) {
        kord.createGlobalChatInputCommand(name, description) {
            // Necessary Workaround: subcommand "any" acts as '/whattodrink' without sub-commands to select any category-independent tea
            subCommand(ANY_CATEGORY, "Suggests a random tea")

            // Take first 25 (sub)categories to avoid exceeding Discord's command option limits
            TeaCategory.entries.take(25).forEach { category ->
                // commands need to be lowercase.
                subCommand(category.name.lowercase(), "Suggests a ${category.name.sentenceCase()} tea") {
                    val subCategories = TeaSubCategory.getByMainCategory(category)
                    if (subCategories.isNotEmpty()) {
                        string(
                            SUBCATEGORY,
                            "Suggests a ${category.name.sentenceCase()} tea from a specific sub-category",
                        ) {
                            required = false
                            subCategories.take(25).forEach { sub ->
                                choice(sub.name.sentenceCase(), sub.name)
                            }
                        }
                    }
                }
            }
        }
    }

    override suspend fun handle(interaction: ChatInputCommandInteraction) {
        val response = interaction.deferPublicResponse()

        try {
            val subCommandName = (interaction.command as? SubCommand)?.name ?: ANY_CATEGORY

            if (subCommandName == ANY_CATEGORY) {
                sendRecommendation(response, TeaRepository.getRandomTea().name)
                return
            }

            val category: TeaCategory = TeaCategory.fromString(subCommandName)
                .orElseThrow { IllegalStateException("Received unknown category: $subCommandName") }

            val subCategoryArg = interaction.command.strings[SUBCATEGORY]
            val subCategory: TeaSubCategory? = subCategoryArg?.let {
                TeaSubCategory.fromString(it)
                    .orElseThrow { IllegalStateException("Received unknown sub-category: $it") }
            }

            val tea = TeaRepository.getRandomTeaWith(category, subCategory)
            sendRecommendation(response, tea.name)

        } catch (e: NoSuchElementException) {
            logger.warn("No teas found for the selected criteria! ${e.message}")
            response.respond { content = "No teas found for the selected criteria." }
        } catch (e: Exception) {
            logger.error("Internal error in WhatToDrink: ${e.message}")
            response.respond { content = "An internal error occurred while processing your request." }
        }
    }

    private suspend fun sendRecommendation(
        response: DeferredPublicMessageInteractionResponseBehavior,
        teaName: String,
    ) {
        val suggestion = MessageVariations.suggestions.random().format(teaName)
        response.respond { content = suggestion }
    }

    /**
     * Converts the string to sentence case (first letter capitalized, rest lowercase).
     */
    private fun String.sentenceCase(): String = lowercase().replaceFirstChar { it.titlecase() }

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
