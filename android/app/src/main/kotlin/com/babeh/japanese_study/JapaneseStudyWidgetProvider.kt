package com.babeh.japanese_study

import android.appwidget.AppWidgetManager
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class JapaneseStudyWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: android.content.SharedPreferences) {
        val streak = widgetData.getInt("streak", 0)
        val xp = widgetData.getInt("xp", 0)
        val kanji = widgetData.getString("kanji", "日") ?: "日"
        appWidgetIds.forEach { id ->
            val views = RemoteViews(context.packageName, R.layout.japanese_study_widget)
            views.setTextViewText(R.id.widget_kanji, kanji)
            views.setTextViewText(R.id.widget_streak, "🔥 $streak hari")
            views.setTextViewText(R.id.widget_xp, "$xp XP")
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
