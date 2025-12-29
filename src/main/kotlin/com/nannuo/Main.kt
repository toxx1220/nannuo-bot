package com.nannuo

import com.nannuo.commands.Command
import com.nannuo.commands.Ping
import com.nannuo.commands.WhatToDrink
import dev.kord.core.Kord
import dev.kord.core.event.message.MessageCreateEvent
import dev.kord.core.on
import dev.kord.gateway.Intent
import dev.kord.gateway.PrivilegedIntent
import org.slf4j.LoggerFactory

suspend fun main() {
    val logger = LoggerFactory.getLogger("Main")
    
    val token = System.getenv("DISCORD_TOKEN") 
        ?: System.getenv("DISCORD_TOKEN_PATH")?.let { java.io.File(it).readText().trim() }
        ?: error("Neither DISCORD_TOKEN nor DISCORD_TOKEN_PATH environment variable is set")

    val kord = Kord(token)

    val commands: List<Command> = listOf(
        Ping(),
        WhatToDrink(),
    )
    val commandMap = commands.associateBy { it.name.lowercase() }

    kord.on<MessageCreateEvent> {
        if (message.author?.isBot != false) return@on
        if (!message.content.startsWith("!")) return@on

        val parts = message.content.substring(1) // remove "!"
            .trim()
            .split("\\s+".toRegex())
        val commandName = parts[0].lowercase()
        val args = parts.drop(1) // arguments after command name

        val command = commandMap[commandName]
        if (command != null) {
            try {
                command.execute(message, args)
            } catch (e: Exception) {
                logger.error("Error executing command $commandName", e)
                message.channel.createMessage("Something went wrong while executing that command.")
            }
        }
    }

    logger.info("Bot is logging in...")
    kord.login {
        @OptIn(PrivilegedIntent::class)
        intents += Intent.MessageContent
    }
}
