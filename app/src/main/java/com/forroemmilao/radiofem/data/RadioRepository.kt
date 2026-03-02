package com.forroemmilao.radiofem.data

import com.forroemmilao.radiofem.BuildConfig
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory

class RadioRepository {
    private val api: AzuraCastService by lazy {
        Retrofit.Builder()
            .baseUrl(BuildConfig.BASE_URL)
            .addConverterFactory(GsonConverterFactory.create())
            .build()
            .create(AzuraCastService::class.java)
    }

    suspend fun fetchNowPlaying(): NowPlayingResponse {
        return api.getNowPlaying(BuildConfig.STATION_SHORTCODE)
    }

    suspend fun fetchSchedule(startDate: String? = null, endDate: String? = null): List<ScheduleItemResponse> {
        return api.getSchedule(
            BuildConfig.STATION_SHORTCODE,
            startDate = startDate,
            endDate = endDate
        )
    }

    suspend fun fetchPodcasts(): List<PodcastResponse> {
        return api.getPodcasts(BuildConfig.STATION_SHORTCODE)
    }

    suspend fun fetchPodcastEpisodes(podcastId: String): List<PodcastEpisodeResponse> {
        return api.getPodcastEpisodes(BuildConfig.STATION_SHORTCODE, podcastId)
    }
}
