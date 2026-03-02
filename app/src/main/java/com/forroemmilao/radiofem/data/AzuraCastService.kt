package com.forroemmilao.radiofem.data

import retrofit2.http.GET
import retrofit2.http.Path
import retrofit2.http.Query

interface AzuraCastService {
    @GET("api/nowplaying/{station}")
    suspend fun getNowPlaying(@Path("station") stationShortcode: String): NowPlayingResponse

    @GET("api/station/{station}/schedule")
    suspend fun getSchedule(
        @Path("station") stationShortcode: String,
        @Query("start") startDate: String? = null,
        @Query("end") endDate: String? = null
    ): List<ScheduleItemResponse>

    @GET("api/station/{station}/public/podcasts")
    suspend fun getPodcasts(@Path("station") stationShortcode: String): List<PodcastResponse>

    @GET("api/station/{station}/public/podcast/{podcastId}/episodes")
    suspend fun getPodcastEpisodes(
        @Path("station") stationShortcode: String,
        @Path("podcastId") podcastId: String
    ): List<PodcastEpisodeResponse>
}
