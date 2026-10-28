package com.kyant.backdrop.catalog

import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.text.BasicText
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.paint
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.kyant.backdrop.backdrops.layerBackdrop
import com.kyant.backdrop.backdrops.rememberLayerBackdrop
import com.kyant.backdrop.catalog.components.LiquidBottomTab
import com.kyant.backdrop.catalog.components.LiquidBottomTabs

// Comparison harness only: the library, optics and animation are unmodified.
@Composable
fun ComparisonContent() {
    val backdrop = rememberLayerBackdrop()
    var selected by remember { mutableIntStateOf(0) }
    val icon = painterResource(R.drawable.flight_40px)
    Box(Modifier.fillMaxSize()) {
        Image(painterResource(R.drawable.system_home_screen_light), null,
            Modifier.fillMaxSize().layerBackdrop(backdrop), contentScale = ContentScale.Crop)
        LiquidBottomTabs(
            selectedTabIndex = { selected }, onTabSelected = { selected = it },
            backdrop = backdrop, tabsCount = 5,
            modifier = Modifier.align(Alignment.BottomCenter).navigationBarsPadding()
                .padding(horizontal = 12.dp).padding(bottom = 12.dp)
        ) {
            repeat(5) { index ->
                LiquidBottomTab({ selected = index }) {
                    Box(Modifier.size(24.dp).paint(icon, colorFilter = ColorFilter.tint(Color.Black)))
                    BasicText("Tab ${index + 1}", style = TextStyle(Color.Black, 12.sp))
                }
            }
        }
    }
}
