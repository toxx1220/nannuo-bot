package com.nannuo

import com.nannuo.commands.Command
import com.nannuo.commands.WhatToDrink
import dev.kord.core.Kord
import dev.kord.core.event.interaction.ChatInputCommandInteractionCreateEvent
import dev.kord.core.on
import org.slf4j.LoggerFactory

suspend fun main() {
    val logger = LoggerFactory.getLogger("Main")

    val token = System.getenv("DISCORD_TOKEN")
        ?: System.getenv("DISCORD_TOKEN_PATH")?.let { java.io.File(it).readText().trim() }
        ?: error("Neither DISCORD_TOKEN nor DISCORD_TOKEN_PATH environment variable is set")

    val kord = Kord(token)

    val commands: List<Command> = listOf(
        WhatToDrink(),
    )
    val commandMap = commands.associateBy { it.name }

    logger.info("Registering commands...")
    commands.forEach { command ->
        command.register(kord)
        logger.info("Registered command: ${command.name}")
    }

    kord.on<ChatInputCommandInteractionCreateEvent> {
        val command = commandMap[interaction.command.rootName]
        if (command != null) {
            try {
                command.handle(interaction)
            } catch (e: Exception) {
                logger.error("Error executing command ${interaction.command.rootName}", e)
            }
        }
    }

    logger.info("Bot is logging in...")
    kord.login()
}
