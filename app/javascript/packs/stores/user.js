import { defineStore } from 'pinia'
import axios from 'axios'

export const useUserStore = defineStore('user', {
  state: () => ({
    token: localStorage.getItem('token') || null,
    userInfo: JSON.parse(localStorage.getItem('userInfo') || 'null')
  }),

  getters: {
    isLoggedIn: (state) => !!state.token,
    isAdmin: (state) => state.userInfo?.role === 'admin',
    isStaff: (state) => state.userInfo?.role === 'staff' || state.userInfo?.role === 'admin',
    userName: (state) => state.userInfo?.name || '',
    userRole: (state) => state.userInfo?.role_name || ''
  },

  actions: {
    login(token, user) {
      this.token = token
      this.userInfo = user
      
      localStorage.setItem('token', token)
      localStorage.setItem('userInfo', JSON.stringify(user))
      
      return { success: true }
    },

    async logout() {
      try {
        await axios.delete('/api/v1/logout')
      } catch (error) {
        console.error('Logout error:', error)
      } finally {
        this.token = null
        this.userInfo = null
        localStorage.removeItem('token')
        localStorage.removeItem('userInfo')
      }
    },

    async fetchUserInfo() {
      try {
        const response = await axios.get('/api/v1/current_user')
        this.userInfo = response.data
        localStorage.setItem('userInfo', JSON.stringify(response.data))
        return response.data
      } catch (error) {
        console.error('Fetch user info error:', error)
        return null
      }
    },

    updateUserInfo(userInfo) {
      this.userInfo = userInfo
      localStorage.setItem('userInfo', JSON.stringify(userInfo))
    }
  }
})
