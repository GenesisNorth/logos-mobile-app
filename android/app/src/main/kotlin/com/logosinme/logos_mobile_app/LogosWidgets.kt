package com.logosinme.logos_mobile_app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.text.Layout
import android.text.StaticLayout
import android.text.TextPaint
import android.text.TextUtils
import android.util.TypedValue
import android.view.View
import android.widget.RemoteViews
import androidx.core.content.res.ResourcesCompat
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/** Terracotta verse widget — reference, the week's phrase, today's status. */
class LogosVerseWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { id ->
            val views = RemoteViews(context.packageName, R.layout.widget_verse).apply {
                setTextViewText(R.id.ref, widgetData.getString("ref", "JOHN 15:5"))
                val phrase = widgetData.getString("phrase", "Abide in me.") ?: ""
                setTextViewText(R.id.phrase, phrase)
                val widthDp = appWidgetManager.getAppWidgetOptions(id)
                    .getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 140).coerceAtLeast(110)
                renderDisplayText(context, phrase, widthDp - 32)?.let {
                    setImageViewBitmap(R.id.phrase_image, it)
                    setViewVisibility(R.id.phrase_image, View.VISIBLE)
                    setViewVisibility(R.id.phrase, View.GONE)
                }
                setTextViewText(R.id.status, statusLine(widgetData))
                setOnClickPendingIntent(R.id.widget_root, HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java))
            }
            appWidgetManager.updateAppWidget(id, views)
        }
    }

    private fun statusLine(d: SharedPreferences): String = when (d.getString("status", "today")) {
        "today" -> d.getString("headline", "Day 1 · Today") ?: ""
        "complete" -> "Week kept"
        else -> "${d.getString("nextName", "")} · at midnight"
    }
}

/** Cream "This week" widget — four seeds and the streak. */
class LogosWeekWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        val days = (widgetData.getString("days", "today,locked,locked,locked") ?: "").split(",")
        val seeds = listOf(R.id.seed1, R.id.seed2, R.id.seed3, R.id.seed4)
        val streak = readInt(widgetData, "streak")
        appWidgetIds.forEach { id ->
            val views = RemoteViews(context.packageName, R.layout.widget_week).apply {
                seeds.forEachIndexed { i, seed ->
                    setImageViewResource(seed, when (days.getOrNull(i)) {
                        "done" -> R.drawable.seed_done
                        "today" -> R.drawable.seed_today
                        else -> R.drawable.seed_locked
                    })
                }
                setTextViewText(R.id.next, if (widgetData.getString("status", "") == "resting") widgetData.getString("headline", "") else "")
                setTextViewText(R.id.streak, "$streak-day streak")
                setOnClickPendingIntent(R.id.widget_root, HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java))
            }
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}

/** home_widget stores Dart ints as Long; read either. */
internal fun readInt(d: SharedPreferences, key: String): Long =
    try { d.getLong(key, 0L) } catch (_: ClassCastException) { d.getInt(key, 0).toLong() }

/**
 * Draws [text] in the design's Caprasimo display face (launchers don't apply
 * custom font resources inside widget layouts).
 */
internal fun renderDisplayText(context: Context, text: String, widthDp: Int, sizeSp: Float = 21f): Bitmap? = try {
    val dm = context.resources.displayMetrics
    val paint = TextPaint(TextPaint.ANTI_ALIAS_FLAG).apply {
        typeface = ResourcesCompat.getFont(context, R.font.caprasimo)
        color = Color.parseColor("#F9F4ED")
        textSize = TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_SP, sizeSp, dm)
    }
    val width = (widthDp * dm.density).toInt().coerceAtLeast(1)
    val layout = StaticLayout.Builder.obtain(text, 0, text.length, paint, width)
        .setAlignment(Layout.Alignment.ALIGN_NORMAL)
        .setLineSpacing(0f, 0.95f)
        .setMaxLines(3)
        .setEllipsize(TextUtils.TruncateAt.END)
        .build()
    Bitmap.createBitmap(width, layout.height.coerceAtLeast(1), Bitmap.Config.ARGB_8888).also {
        layout.draw(Canvas(it))
    }
} catch (_: Exception) {
    null
}
