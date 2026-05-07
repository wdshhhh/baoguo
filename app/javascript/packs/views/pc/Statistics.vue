<template>
  <div class="statistics">
    <el-card class="mb-4">
      <template #header>
        <div class="card-header">
          <h2>数据统计</h2>
          <div class="date-range">
            <el-date-picker
              v-model="dateRange"
              type="daterange"
              range-separator="至"
              start-placeholder="开始日期"
              end-placeholder="结束日期"
              @change="loadStatistics"
            />
          </div>
        </div>
      </template>
      
      <div class="stats-overview">
        <el-row :gutter="20">
          <el-col :span="6">
            <el-card shadow="hover" class="stat-card">
              <div class="stat-content">
                <div class="stat-number">{{ todayStats.in_count }}</div>
                <div class="stat-label">今日入库</div>
              </div>
            </el-card>
          </el-col>
          <el-col :span="6">
            <el-card shadow="hover" class="stat-card">
              <div class="stat-content">
                <div class="stat-number">{{ todayStats.out_count }}</div>
                <div class="stat-label">今日出库</div>
              </div>
            </el-card>
          </el-col>
          <el-col :span="6">
            <el-card shadow="hover" class="stat-card">
              <div class="stat-content">
                <div class="stat-number">{{ todayStats.pending_count }}</div>
                <div class="stat-label">待取件</div>
              </div>
            </el-card>
          </el-col>
          <el-col :span="6">
            <el-card shadow="hover" class="stat-card">
              <div class="stat-content">
                <div class="stat-number">{{ todayStats.exception_count }}</div>
                <div class="stat-label">异常包裹</div>
              </div>
            </el-card>
          </el-col>
        </el-row>
      </div>
      
      <div class="charts-section">
        <el-card class="mb-4">
          <template #header>
            <div class="chart-header">
              <h3>包裹趋势</h3>
            </div>
          </template>
          <div class="chart-container">
            <div ref="trendChart" style="width: 100%; height: 400px;"></div>
          </div>
        </el-card>
        
        <el-card class="mb-4">
          <template #header>
            <div class="chart-header">
              <h3>包裹状态分布</h3>
            </div>
          </template>
          <div class="chart-container">
            <div ref="statusChart" style="width: 100%; height: 400px;"></div>
          </div>
        </el-card>
        
        <el-card class="mb-4">
          <template #header>
            <div class="chart-header">
              <h3>快递公司分布</h3>
            </div>
          </template>
          <div class="chart-container">
            <div ref="carrierChart" style="width: 100%; height: 400px;"></div>
          </div>
        </el-card>
      </div>
      
      <div class="export-section">
        <el-button type="primary" @click="exportStatistics">
          <el-icon><Download /></el-icon>
          导出报表
        </el-button>
      </div>
    </el-card>
  </div>
</template>

<script>
import { Download } from '@element-plus/icons-vue'
import { ref, onMounted, watch } from 'vue'
import * as echarts from 'echarts'

export default {
  name: 'Statistics',
  setup() {
    const dateRange = ref([])
    const todayStats = ref({
      in_count: 0,
      out_count: 0,
      pending_count: 0,
      exception_count: 0
    })
    const trendChart = ref(null)
    const statusChart = ref(null)
    const carrierChart = ref(null)
    const trendChartInstance = ref(null)
    const statusChartInstance = ref(null)
    const carrierChartInstance = ref(null)
    
    const loadStatistics = () => {
      // 模拟数据
      todayStats.value = {
        in_count: 120,
        out_count: 95,
        pending_count: 25,
        exception_count: 5
      }
      
      renderTrendChart()
      renderStatusChart()
      renderCarrierChart()
    }
    
    const renderTrendChart = () => {
      if (!trendChart.value) return
      
      if (trendChartInstance.value) {
        trendChartInstance.value.dispose()
      }
      
      trendChartInstance.value = echarts.init(trendChart.value)
      
      const option = {
        title: {
          text: '近7天包裹趋势'
        },
        tooltip: {
          trigger: 'axis'
        },
        legend: {
          data: ['入库', '出库']
        },
        grid: {
          left: '3%',
          right: '4%',
          bottom: '3%',
          containLabel: true
        },
        xAxis: {
          type: 'category',
          boundaryGap: false,
          data: ['3月27日', '3月28日', '3月29日', '3月30日', '3月31日', '4月1日', '4月2日']
        },
        yAxis: {
          type: 'value'
        },
        series: [
          {
            name: '入库',
            type: 'line',
            stack: 'Total',
            data: [120, 132, 101, 134, 90, 230, 210]
          },
          {
            name: '出库',
            type: 'line',
            stack: 'Total',
            data: [110, 122, 91, 124, 80, 210, 190]
          }
        ]
      }
      
      trendChartInstance.value.setOption(option)
    }
    
    const renderStatusChart = () => {
      if (!statusChart.value) return
      
      if (statusChartInstance.value) {
        statusChartInstance.value.dispose()
      }
      
      statusChartInstance.value = echarts.init(statusChart.value)
      
      const option = {
        title: {
          text: '包裹状态分布'
        },
        tooltip: {
          trigger: 'item'
        },
        legend: {
          orient: 'vertical',
          left: 'left'
        },
        series: [
          {
            name: '状态',
            type: 'pie',
            radius: '50%',
            data: [
              { value: 150, name: '已取件' },
              { value: 25, name: '待取件' },
              { value: 5, name: '异常' }
            ],
            emphasis: {
              itemStyle: {
                shadowBlur: 10,
                shadowOffsetX: 0,
                shadowColor: 'rgba(0, 0, 0, 0.5)'
              }
            }
          }
        ]
      }
      
      statusChartInstance.value.setOption(option)
    }
    
    const renderCarrierChart = () => {
      if (!carrierChart.value) return
      
      if (carrierChartInstance.value) {
        carrierChartInstance.value.dispose()
      }
      
      carrierChartInstance.value = echarts.init(carrierChart.value)
      
      const option = {
        title: {
          text: '快递公司分布'
        },
        tooltip: {
          trigger: 'axis',
          axisPointer: {
            type: 'shadow'
          }
        },
        grid: {
          left: '3%',
          right: '4%',
          bottom: '3%',
          containLabel: true
        },
        xAxis: {
          type: 'value'
        },
        yAxis: {
          type: 'category',
          data: ['顺丰', '圆通', '中通', '韵达', '申通']
        },
        series: [
          {
            name: '包裹数',
            type: 'bar',
            data: [40, 30, 25, 20, 15]
          }
        ]
      }
      
      carrierChartInstance.value.setOption(option)
    }
    
    const exportStatistics = () => {
      // 实现导出报表功能
      console.log('导出报表')
    }
    
    onMounted(() => {
      loadStatistics()
      
      window.addEventListener('resize', () => {
        trendChartInstance.value?.resize()
        statusChartInstance.value?.resize()
        carrierChartInstance.value?.resize()
      })
    })
    
    return {
      dateRange,
      todayStats,
      trendChart,
      statusChart,
      carrierChart,
      loadStatistics,
      exportStatistics
    }
  }
}
</script>

<style scoped>
.statistics {
  padding: 0;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.stats-overview {
  margin-bottom: 30px;
}

.stat-card {
  height: 120px;
}

.stat-content {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 100%;
}

.stat-number {
  font-size: 24px;
  font-weight: bold;
  color: #007bff;
  margin-bottom: 10px;
}

.stat-label {
  font-size: 14px;
  color: #666;
}

.charts-section {
  margin-bottom: 30px;
}

.chart-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.chart-container {
  margin-top: 20px;
}

.export-section {
  display: flex;
  justify-content: flex-end;
  margin-top: 20px;
}
</style>
