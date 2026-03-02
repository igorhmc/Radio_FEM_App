package com.forroemmilao.radiofem.data

import com.google.gson.annotations.SerializedName

data class NowPlayingResponse(
    @SerializedName("station")
    val station: Station = Station(),
    @SerializedName("listeners")
    val listeners: Listeners = Listeners(),
    @SerializedName("now_playing")
    val nowPlaying: NowPlaying = NowPlaying()
)

data class Station(
    @SerializedName("name")
    val name: String = "",
    @SerializedName("listen_url")
    val listenUrl: String = ""
)

data class Listeners(
    @SerializedName("current")
    val current: Int = 0
)

data class NowPlaying(
    @SerializedName("song")
    val song: Song = Song()
)

data class Song(
    @SerializedName("text")
    val text: String = "",
    @SerializedName("artist")
    val artist: String = "",
    @SerializedName("title")
    val title: String = ""
)

data class ScheduleItemResponse(
    @SerializedName("id")
    val id: Long = 0L,
    @SerializedName("title")
    val title: String = "",
    @SerializedName("description")
    val description: String = "",
    @SerializedName("start")
    val start: String = "",
    @SerializedName("end")
    val end: String = "",
    @SerializedName("is_now")
    val isNow: Boolean = false
)

data class PodcastResponse(
    @SerializedName("id")
    val id: String = "",
    @SerializedName("title")
    val title: String = "",
    @SerializedName("description_short")
    val descriptionShort: String = "",
    @SerializedName("author")
    val author: String = "",
    @SerializedName("episodes")
    val episodesCount: Int = 0,
    @SerializedName("language_name")
    val languageName: String = "",
    @SerializedName("links")
    val links: PodcastLinks = PodcastLinks()
)

data class PodcastLinks(
    @SerializedName("episodes")
    val episodes: String = "",
    @SerializedName("public_feed")
    val publicFeed: String = ""
)

data class PodcastEpisodeResponse(
    @SerializedName("id")
    val id: String = "",
    @SerializedName("title")
    val title: String = "",
    @SerializedName("description_short")
    val descriptionShort: String = "",
    @SerializedName("publish_at")
    val publishAt: Long? = null,
    @SerializedName("created_at")
    val createdAt: Long? = null,
    @SerializedName("links")
    val links: PodcastEpisodeLinks = PodcastEpisodeLinks()
)

data class PodcastEpisodeLinks(
    @SerializedName("download")
    val download: String = "",
    @SerializedName("public")
    val publicUrl: String = ""
)
