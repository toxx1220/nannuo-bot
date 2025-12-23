package com.nannuo

import dev.kord.core.Kord
import dev.kord.core.event.message.MessageCreateEvent
import dev.kord.core.on
import dev.kord.gateway.Intent
import dev.kord.gateway.PrivilegedIntent

suspend fun main() {
    val token = System.getenv("DISCORD_TOKEN") ?: error("DISCORD_TOKEN environment variable not set")

    val kord = Kord(token)

    kord.on<MessageCreateEvent> {
        if (message.author?.isBot != false) return@on
        
        if (message.content == "!ping") {
            message.channel.createMessage("Pong!")
        }
    }

    println("Bot is logging in...")
    kord.login {
        // We need MessageContent intent to read message content
        @OptIn(PrivilegedIntent::class)
        intents += Intent.MessageContent
    }
}
