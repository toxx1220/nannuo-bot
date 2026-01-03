package com.nannuo.commands

import dev.kord.core.Kord
import dev.kord.core.behavior.interaction.response.respond
import dev.kord.core.entity.interaction.ChatInputCommandInteraction

class Ping : Command {
    override val name: String = "ping"
    override val description: String = "Responds with Pong!"


    override suspend fun register(kord: Kord) {
        kord.createGlobalChatInputCommand(name, description)
    }

    override suspend fun handle(interaction: ChatInputCommandInteraction) {
        val response = interaction.deferPublicResponse()
        response.respond { content = "Pong!" }
    }
}
