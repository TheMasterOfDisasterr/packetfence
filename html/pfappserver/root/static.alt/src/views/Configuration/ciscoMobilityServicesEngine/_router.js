import store from '@/store'
import BasesStoreModule from '../bases/_store'

const TheView = () => import(/* webpackChunkName: "Configuration" */ './_components/TheView')

export const beforeEnter = (to, from, next = () => {}) => {
  if (!store.state.$_bases) {
    store.registerModule('$_bases', BasesStoreModule)
  }
  next()
}

export default [
  {
    path: 'mse',
    name: 'mse',
    component: TheView,
    props: (route) => ({ query: route.query.query }),
    beforeEnter
  }
]
