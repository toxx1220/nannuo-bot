package com.nannuo.commands

import com.nannuo.domain.TeaCategory
import com.nannuo.domain.TeaRepository
import dev.kord.core.entity.Message

class WhatToDrink : Command {
    override val name: String = "whattodrink"
    override val description: String = "Suggests a random tea for you."

    override suspend fun execute(
        message: Message,
        args: List<String>,
    ) {
        if (args.isEmpty())
            return sendRecommendation(message, TeaRepository.getRandomTea().name)

        try {
            val teaCategory = TeaCategory.valueOf(args[0].uppercase())
            return sendRecommendation(message, TeaRepository.getRandomTeaWith(teaCategory).name)
        } catch (e: IllegalArgumentException) {
            message.channel.createMessage("Invalid category '${args[0]}'. Valid categories are: ${TeaCategory.entries.joinToString(", ") { it.name.lowercase() }}.") // TODO: Implement user categories
            return
        }
    }

    private suspend fun sendRecommendation(message: Message, teaName: String) {
        val suggestion = MessageVariations.suggestions.random().format(teaName)
        message.channel.createMessage(suggestion)
    }

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
