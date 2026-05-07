<template>
  <div class="dashboard">
    <!-- 今日概览统计卡片 -->
    <el-card class="mb-4">
      <template #header>
        <div class="card-header">
          <span class="header-title">今日概览</span>
          <el-tag type="info">{{ currentDate }}</el-tag>
        </div>
      </template>
      <div class="stats-grid">
        <el-statistic
          v-for="(stat, index) in stats"
          :key="index"
          class="stat-item"
          :title="stat.title"
          :value="stat.value"
          :value-style="{ color: stat.color, fontSize: '28px', fontWeight: 'bold' }"
        >
          <template #prefix>
            <el-icon :size="32" :color="stat.color" style="margin-right: 8px;">
              <component :is="stat.icon" />
            </el-icon>
          </template>
        </el-statistic>
      </div>
    </el-card>

    <!-- 数据图表 -->
    <el-row :gutter="20" class="mb-4">
      <el-col :span="16">
        <el-card>
          <template #header>
            <div class="card-header">
              <span class="header-title">近7天包裹趋势</span>
              <el-radio-group v-model="chartType" size="small">
                <el-radio-button value="stored">入库</el-radio-button>
                <el-radio-button value="picked_up">出库</el-radio-button>
                <el-radio-button value="both">全部</el-radio-button>
              </el-radio-group>
            </div>
          </template>
          <div ref="trendChart" style="height: 300px;"></div>
        </el-card>
      </el-col>
      <el-col :span="8">
        <el-card>
          <template #header>
            <div class="card-header">
              <span class="header-title">包裹状态分布</span>
            </div>
          </template>
          <div ref="statusChart" style="height: 300px;"></div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 快捷操作 -->
    <el-card class="mb-4">
      <template #header>
        <div class="card-header">
          <span class="header-title">快捷操作</span>
        </div>
      </template>
      <div class="quick-actions">
        <el-button type="primary" size="large" @click="goToPackages">
          <el-icon><Plus /></el-icon>
          包裹入库
        </el-button>
        <el-button type="success" size="large" @click="goToScan">
          <el-icon><View /></el-icon>
          扫码出库
        </el-button>
        <el-button type="warning" size="large" @click="goToExceptions">
          <el-icon><Warning /></el-icon>
          异常处理
        </el-button>
        <el-button type="info" size="large" @click="goToStatistics">
          <el-icon><TrendCharts /></el-icon>
          数据统计
        </el-button>
      </div>
    </el-card>
    
    <!-- 最近活动 -->
    <el-card>
      <template #header>
        <div class="card-header">
          <span class="header-title">最近活动</span>
          <el-button type="primary" link @click="refreshActivities">
            <el-icon><Refresh /></el-icon>
            刷新
          </el-button>
        </div>
      </template>
      <el-timeline>
        <el-timeline-item
          v-for="(activity, index) in recentActivities"
          :key="index"
          :type="getActivityType(activity.action)"
          :timestamp="activity.time"
        >
          <div class="activity-content">
            <span class="activity-action">{{ activity.action }}</span>
            <el-tag size="small" type="info">{{ activity.user }}</el-tag>
          </div>
        </el-timeline-item>
      </el-timeline>
    </el-card>
  </div>
</template>

<script>
import { ref, onMounted, nextTick, watch } from 'vue'
import { useRouter } from 'vue-router'
import { 
  Goods, 
  TakeawayBox, 
  Warning, 
  Clock, 
  Plus, 
  TrendCharts,
  Refresh,
  Box,
  Check,
  Close,
  View
} from '@element-plus/icons-vue'
import axios from 'axios'
import * as echarts from 'echarts'

export default {
  name: 'PCDashboard',
  components: {
    Goods,
    TakeawayBox,
    Warning,
    Clock,
    Plus,
    TrendCharts,
    Refresh,
    Box,
    Check,
    Close,
    View
  },
  setup() {
    const router = useRouter()
    const trendChart = ref(null)
    const statusChart = ref(null)
    const chartType = ref('both')
    
    const currentDate = ref(new Date().toLocaleDateString('zh-CN'))
    
    const stats = ref([
      { title: '今日入库', value: 0, color: '#409EFF', icon: 'Goods' },
      { title: '今日出库', value: 0, color: '#67C23A', icon: 'TakeawayBox' },
      { title: '异常包裹', value: 0, color: '#E6A23C', icon: 'Warning' },
      { title: '待处理', value: 0, color: '#F56C6C', icon: 'Clock' }
    ])
    
    const recentActivities = ref([])
    const chartData = ref({ dates: [], stored: [], picked_up: [] })
    
    let trendChartInstance = null
    let statusChartInstance = null

    const fetchStats = async () => {
      try {
        const response = await axios.get('/api/v1/dashboard/stats')
        if (response.data && response.data.success) {
          const data = response.data.data
          stats.value[0].value = data.today_stored || 0
          stats.value[1].value = data.today_picked_up || 0
          stats.value[2].value = data.exception_count || 0
          stats.value[3].value = data.pending_count || 0
        }
      } catch (error) {
        console.error('获取统计数据失败', error)
        // 使用模拟数据
        stats.value[0].value = 15
        stats.value[1].value = 8
        stats.value[2].value = 2
        stats.value[3].value = 5
      }
    }

    const fetchChartData = async () => {
      try {
        const response = await axios.get('/api/v1/dashboard/chart_data')
        if (response.data && response.data.success) {
          chartData.value = response.data.data
        }
      } catch (error) {
        console.error('获取图表数据失败', error)
        // 使用模拟数据
        chartData.value = {
          dates: ['04-01', '04-02', '04-03', '04-04', '04-05', '04-06', '04-07'],
          stored: [12, 15, 8, 20, 18, 25, 15],
          picked_up: [10, 8, 12, 15, 20, 18, 8]
        }
      }
    }

    const fetchRecentActivities = async () => {
      try {
        const response = await axios.get('/api/v1/dashboard/recent_activities')
        if (response.data && response.data.success) {
          recentActivities.value = response.data.data
        }
      } catch (error) {
        console.error('获取最近活动失败', error)
        // 使用模拟数据
        recentActivities.value = [
          { time: '2026-04-02 10:30', action: '包裹入库（运单号：SF1234567890）', user: '管理员' },
          { time: '2026-04-02 09:15', action: '包裹出库（运单号：YT9876543210）', user: '工作人员' },
          { time: '2026-04-01 18:45', action: '标记异常包裹（运单号：JD5678901234）', user: '工作人员' },
          { time: '2026-04-01 16:20', action: '包裹入库（运单号：SF0987654321）', user: '管理员' },
          { time: '2026-04-01 14:00', action: '包裹出库（运单号：YT1234567890）', user: '工作人员' }
        ]
      }
    }

    const initTrendChart = () => {
      if (trendChart.value) {
        trendChartInstance = echarts.init(trendChart.value)
        updateTrendChart()
      }
    }

    const updateTrendChart = () => {
      if (!trendChartInstance) return

      const series = []
      
      if (chartType.value === 'stored' || chartType.value === 'both') {
        series.push({
          name: '入库',
          type: 'line',
          data: chartData.value.stored,
          smooth: true,
          areaStyle: {
            color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
              { offset: 0, color: 'rgba(64, 158, 255, 0.3)' },
              { offset: 1, color: 'rgba(64, 158, 255, 0.05)' }
            ])
          },
          itemStyle: { color: '#409EFF' },
          lineStyle: { width: 3 }
        })
      }
      
      if (chartType.value === 'picked_up' || chartType.value === 'both') {
        series.push({
          name: '出库',
          type: 'line',
          data: chartData.value.picked_up,
          smooth: true,
          areaStyle: {
            color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
              { offset: 0, color: 'rgba(103, 194, 58, 0.3)' },
              { offset: 1, color: 'rgba(103, 194, 58, 0.05)' }
            ])
          },
          itemStyle: { color: '#67C23A' },
          lineStyle: { width: 3 }
        })
      }

      const option = {
        tooltip: {
          trigger: 'axis',
          axisPointer: { type: 'cross' }
        },
        legend: {
          data: series.map(s => s.name),
          bottom: 0
        },
        grid: {
          left: '3%',
          right: '4%',
          bottom: '15%',
          containLabel: true
        },
        xAxis: {
          type: 'category',
          boundaryGap: false,
          data: chartData.value.dates
        },
        yAxis: {
          type: 'value',
          minInterval: 1
        },
        series: series
      }

      trendChartInstance.setOption(option, true)
    }

    const initStatusChart = () => {
      if (statusChart.value) {
        statusChartInstance = echarts.init(statusChart.value)
        
        const option = {
          tooltip: {
            trigger: 'item',
            formatter: '{b}: {c} ({d}%)'
          },
          legend: {
            orient: 'vertical',
            left: 'left'
          },
          series: [
            {
              name: '包裹状态',
              type: 'pie',
              radius: ['40%', '70%'],
              avoidLabelOverlap: false,
              itemStyle: {
                borderRadius: 10,
                borderColor: '#fff',
                borderWidth: 2
              },
              label: {
                show: false,
                position: 'center'
              },
              emphasis: {
                label: {
                  show: true,
                  fontSize: 20,
                  fontWeight: 'bold'
                }
              },
              labelLine: {
                show: false
              },
              data: [
                { value: stats.value[3].value, name: '待取件', itemStyle: { color: '#409EFF' } },
                { value: stats.value[1].value, name: '已取件', itemStyle: { color: '#67C23A' } },
                { value: stats.value[2].value, name: '异常', itemStyle: { color: '#E6A23C' } }
              ]
            }
          ]
        }

        statusChartInstance.setOption(option)
      }
    }

    const getActivityType = (action) => {
      if (action.includes('入库')) return 'primary'
      if (action.includes('出库')) return 'success'
      if (action.includes('异常')) return 'warning'
      return 'info'
    }

    const refreshActivities = () => {
      fetchRecentActivities()
    }

    const goToPackages = () => {
      router.push('/pc/packages')
    }

    const goToScan = () => {
      router.push('/pc/scan')
    }

    const goToExceptions = () => {
      router.push('/pc/exceptions')
    }

    const goToStatistics = () => {
      router.push('/pc/statistics')
    }

    watch(chartType, () => {
      updateTrendChart()
    })

    onMounted(async () => {
      await fetchStats()
      await fetchChartData()
      await fetchRecentActivities()
      
      nextTick(() => {
        initTrendChart()
        initStatusChart()
      })

      // 窗口大小改变时重新渲染图表
      window.addEventListener('resize', () => {
        trendChartInstance?.resize()
        statusChartInstance?.resize()
      })
    })

    return {
      currentDate,
      stats,
      recentActivities,
      trendChart,
      statusChart,
      chartType,
      getActivityType,
      refreshActivities,
      goToPackages,
      goToScan,
      goToExceptions,
      goToStatistics
    }
  }
}
</script>

<style scoped>
.dashboard {
  padding: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.header-title {
  font-size: 18px;
  font-weight: bold;
  color: #303133;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 20px;
  margin-top: 20px;
}

.stat-item {
  text-align: center;
  padding: 20px;
  background: linear-gradient(135deg, #f5f7fa 0%, #e4e7ed 100%);
  border-radius: 8px;
  transition: transform 0.3s ease;
}

.stat-item:hover {
  transform: translateY(-5px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

.quick-actions {
  display: flex;
  gap: 20px;
  flex-wrap: wrap;
  justify-content: center;
  padding: 20px;
}

.quick-actions .el-button {
  min-width: 150px;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
}

.activity-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 10px;
}

.activity-action {
  flex: 1;
  color: #606266;
}

.mb-4 {
  margin-bottom: 20px;
}

:deep(.el-statistic__head) {
  font-size: 14px;
  color: #606266;
  margin-bottom: 10px;
}

:deep(.el-timeline-item__timestamp) {
  color: #909399;
  font-size: 13px;
}
</style>
