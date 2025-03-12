import { ref, watch } from 'vue'
import { usePreferredDark } from '@vueuse/core'

const isDark = ref(false)
const preferredDark = usePreferredDark()

// 初始化主题
const initTheme = () => {
  // 优先使用本地存储的主题设置
  const savedTheme = localStorage.getItem('theme')
  if (savedTheme) {
    isDark.value = savedTheme === 'dark'
  } else {
    // 如果没有本地存储的主题设置，则使用系统主题
    isDark.value = preferredDark.value
  }
  applyTheme()
}

// 切换主题
const toggleTheme = () => {
  isDark.value = !isDark.value
  localStorage.setItem('theme', isDark.value ? 'dark' : 'light')
  applyTheme()
}

// 应用主题
const applyTheme = () => {
  // 更新 HTML 的 class
  document.documentElement.classList.toggle('dark', isDark.value)
  // 更新 Element Plus 的主题
  document.documentElement.style.colorScheme = isDark.value ? 'dark' : 'light'
}

// 监听系统主题变化
watch(preferredDark, (newValue) => {
  // 只有在没有本地存储的主题设置时，才跟随系统主题
  if (!localStorage.getItem('theme')) {
    isDark.value = newValue
    applyTheme()
  }
})

// 导出主题相关的功能
export const useTheme = () => {
  return {
    isDark,
    toggleTheme,
    initTheme
  }
} 