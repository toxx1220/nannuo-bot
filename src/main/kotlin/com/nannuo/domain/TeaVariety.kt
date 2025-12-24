package com.nannuo.domain

import com.nannuo.domain.TeaCategory.*

data class TeaVariety(
    val name: String,
    val category: TeaCategory,
)

object TeaRepository {

    fun getRandomTea(): TeaVariety = allTeas.random()

    fun getRandomTeaWith(category: TeaCategory): TeaVariety {
        val candidates = allTeas.filter { it.category == category }
        return candidates.random()
    }

    // --- Data Definitions ---

    private val allTeas: List<TeaVariety> by lazy {
        whiteTeas.map { TeaVariety(it, WHITE) } +
        greenTeas.map { TeaVariety(it, GREEN) } +
        yellowTeas.map { TeaVariety(it, YELLOW) } +
        oolongTeas.map { TeaVariety(it, OOLONG) } +
        blackTeas.map { TeaVariety(it, BLACK) } +
        darkTeas.map { TeaVariety(it, DARK) }
    }

    private val whiteTeas = listOf(
        "Shou Mei 2025",
        "Bai Mudan 2025",
        "Bai Hao Yin Zhen 2025",
        "Xiang Shui Bai Cha 2025",
        "Zhulincun Dashu Bai Cha 2025",
        "Slices of Bai Cha",
        "Yue Guang Bai",
        "Shou Mei 2024",
        "Shou Mei 2000",
        "Bai Mudan 2011",
        "Bai Hao Yin Zhen 2023 Taimushan",
        "Bai Hao Yin Zhen 2021",
        "Huangye Bai Cha Bing",
        "Dong Pian Bai Cha 2018"
    )

    private val greenTeas = listOf(
        "Lu Shan Yun Wu 2025",
        "Long Jing 2025",
        "Anji Bai Cha 2025",
        "Yunnan Biluochun 2025",
        "Zhu Ye Qing 2025",
        "Lu'an gua pian 2025",
        "Xinyang Maojian 2025",
        "Jasmine Green Tea 2025",
        "Yunsi 2024",
        "Huoshan Huang Ya",
        "Enshi Yulu",
        "Ganlu",
        "Rizhu",
        "Tuanshan Zhu Lin Ye Cha",
        "Jin Zi Sun",
        "Guzhu Cha Bing",
        "Xiang Ya 2021",
        "Matcha Nagomi",
        "Ocean Matcha",
        "Kamairicha Ashikita Organic",
        "Gyokuro Superior",
        "Sencha Koshun Superior",
        "Shuntaro Shincha 2025",
        "Sencha Fukamushi",
        "Sencha Zairai",
        "Sencha Yabukita",
        "Sencha Yabukita 1999",
        "Kukicha Yame",
        "Genmaicha Yabukita",
        "Genmaicha Zairai"
    )

    private val yellowTeas = listOf(
        "Jun Shan Yin Zhen",
        "Mengding Huang Ya",
        "Mengding Huang Cha",
        "Huoshan Huang Cha"
    )

    private val oolongTeas = listOf(
        "Anxi Mei Zhan",
        "High Fire Hong Kong Tieguanyin",
        "Qing Xiang Tieguanyin",
        "Qing Xiang Tieguanyin 2025",
        "Qing Xiang Tieguanyin Superior 2025",
        "Qing Xiang Tieguanyin Wang 2025",
        "Traditional Tieguanyin",
        "Traditional Tieguanyin 2025",
        "Vintage Tieguanyin 2007",
        "Vintage Tieguanyin 2003",
        "GABA",
        "Huang Xin Wu Long",
        "Muzha Tieguanyin",
        "Si Ji Chun",
        "Cui yu 2023",
        "Bi Yu",
        "Fanzhuang Jin Xuan",
        "Ali Shan Jin Xuan",
        "Foshou Alishan",
        "Dong Fang Mei Ren 2023",
        "Dong Fang Mei Ren 2022",
        "Yingxiang Shanlinxi",
        "Ying Xiang Hong Oolong",
        "Handmade Dong Ding 2025",
        "Handmade Dong Ding 2024 Second batch",
        "Handmade Dong Ding 2024",
        "Handmade Dong Ding 2023",
        "Dong Ding 2014",
        "Zhushan Dong Ding light",
        "Zhushan Dong Ding dark",
        "Pinglin Rougui",
        "Pinglin Baozhong",
        "Qingxin Baozhong",
        "Qingxin Baozhong 2022",
        "Baozhong 1970",
        "Qi Lan",
        "Foshou",
        "Da Hong Pao",
        "Shui Xian",
        "Xianrenyan Gao Cong Shui Xian",
        "Beidouyan Shui Xian",
        "Laocong Shui Xian",
        "Wusandi Laocong Shui Xian",
        "High Fire Shui Xian",
        "Organic Rougui",
        "Yangdunyan Rougui",
        "Bishiyan Rougui",
        "Matouyan Rougui",
        "Tieluohan",
        "Aged Tieluohan",
        "Ya Shi Xiang Roasting Set",
        "Da Wu Ye",
        "Ba Xian",
        "Dong Fang Hong",
        "Lang Cai",
        "Song Zhong",
        "Zhi Lan Xiang",
        "Xingren Xiang",
        "Yu Lan Xiang",
        "Rougui Xiang",
        "Koshun Oolong",
        "Yabukita Oolong",
        "GABA Saeakari",
        "Da Tian Mei Ren",
        "2005 Anxi Dong Ding charcoal roast",
        "Honey-Fragrance Baozhong",
        "Jin Mudan",
        "Hong Oolong"
    )

    private val blackTeas = listOf(
        "Benifuuki wakocha Organic",
        "Zairai wakocha Organic",
        "Shuntaro Wakocha 2025",
        "Guifei Hong Cha",
        "Qing Xin Da Mo Hong Cha",
        "Red Ruby 2022",
        "Zi Sun Xiao Hong Gan",
        "Datian Huang Shan Ye Cha",
        "Tongmuguan Zheng Shan Xiao Zhong Tongmuguan",
        "Smoked Zheng Shan Xiao Zhong Tongmuguan",
        "Masu Zheng Shan Xiao Zhong Tongmuguan",
        "Guadun Zheng Shan Xiao Zhong Tongmuguan",
        "Qi Lan Zheng Shan Xiao Zhong",
        "Gaoshan Zheng Shan Xiao Zhong",
        "Qi Zhong Jin Jun Mei",
        "Qi Lan Jin Jun Mei",
        "Honey Jin Jun Mei",
        "Honey Jin Jun Mei Roasted",
        "Black Rose",
        "Yongde Ye Sheng Hong Cha Gushu",
        "Air-dried Ye Sheng Hong Cha",
        "Sun-dried Ye Sheng Hong Cha",
        "Jin Si Dian Hong",
        "Dian Hong",
        "Wuliang Dian Hong Gushu",
        "Cloud Mountain",
        "Fengqing Gushu Hong Cha Gushu",
        "Qimen Maofeng",
        "Yunnan Hong Cha",
        "Nuomi Xiang Hong Cha",
        "Zi Sun Hong Cha",
        "Da Ye Hong Cha"
    )

    private val darkTeas = listOf(
        "Sheng Pu'er terroir selection",
        "Mansong 2021",
        "Xiangzhuqing 2021",
        "Slices of Sheng",
        "Laobanzhang Hun Cai 2025",
        "Laobanzhang Gushu 2024 Gushu",
        "Laobanzhang 2023",
        "Banpo Lao Zhai 2025 Gushu",
        "Guafengzhai Rain Forest 2025 Qiaomu",
        "Mengku Gushu set",
        "Bulangshan Weidong 2024 Qiaomu",
        "Ergazi 2021 Gushu",
        "Bingdao Huang Pian 2019",
        "Shi Shang Fang Cha 2018",
        "Youle 2014 Gushu",
        "Dong Banshan 2012 Gushu",
        "Kuzhushan 2012",
        "Bingdao 2012",
        "Bingdao 2011 Gushu",
        "Yun Wu Shang Pin 2010 Dashu",
        "Gu Dao Cha Xiang 2007",
        "Hani 2007 Gushu",
        "2006 Sipuyuan Seal Script Edition",
        "Changtai Hao #642 2006",
        "Nannuo Bama Xue Yue 2006",
        "Yiwu Chuanqi 2006 Gushu",
        "Green label Hong Kong 2003",
        "Mengku Sheng Pu'er Set Gushu",
        "Bangdong Yakou 2025 Dashu",
        "Black Koji Heicha",
        "White Koji Heicha",
        "Hong Kong Shu Pu'er Set SHU PU'ER",
        "Shitouzhai San Cha 2019 Gushu Shu Pu'er",
        "Slices of Shu 2021 Shu Pu'er",
        "Mian Dian Zhuan Cha Gushu Shu Pu'er",
        "Banzhang 2021 Shu Pu'er",
        "Guizhen Bulang 2019 Dashu Shu Pu'er",
        "Spring Creek 2018 Gushu Shu Pu'er",
        "Bamboo shu pu'er 2015",
        "Lancang 0081 2013 Shu Pu'er",
        "Fengqing Lao Cha Tou 2020s SHU PU'ER",
        "Liubao Lao Ba Zhong Cha",
        "Liubao #2211",
        "Betel Nut Liubao",
        "Huangye Shi Liang Cha 2022",
        "Lao Shu Hei Zhuan 2017",
        "Qian Liang Cha 2013",
        "Fu Zhuan 2008",
        "Vintage Fu Zhuan 1991"
    )
}
