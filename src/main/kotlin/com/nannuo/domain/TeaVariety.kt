package com.nannuo.domain

import com.nannuo.domain.TeaCategory.BLACK
import com.nannuo.domain.TeaCategory.GREEN
import com.nannuo.domain.TeaCategory.HEICHA
import com.nannuo.domain.TeaCategory.OOLONG
import com.nannuo.domain.TeaCategory.PUER
import com.nannuo.domain.TeaCategory.WHITE
import com.nannuo.domain.TeaCategory.YELLOW
import com.nannuo.domain.TeaSubCategory.ANXI
import com.nannuo.domain.TeaSubCategory.BOUTIQUE
import com.nannuo.domain.TeaSubCategory.CHINESE
import com.nannuo.domain.TeaSubCategory.DANCONG
import com.nannuo.domain.TeaSubCategory.FACTORY
import com.nannuo.domain.TeaSubCategory.JAPANESE
import com.nannuo.domain.TeaSubCategory.TAIWANESE
import com.nannuo.domain.TeaSubCategory.YANCHA
import java.util.Objects.isNull

data class TeaVariety(
    val name: String,
    val mainCategory: TeaCategory,
    val subCategory: TeaSubCategory? = null,
)

object TeaRepository {

    fun getRandomTea(): TeaVariety {
        val randomCategory = TeaCategory.entries.random()
        return getRandomTeaWith(randomCategory, null)
    }

    fun getRandomTeaWith(category: TeaCategory, subCategory: TeaSubCategory?): TeaVariety {
        val candidates = allTeas
            .filter { it.mainCategory == category }
            .filter { isNull(subCategory) || it.subCategory == subCategory }

        return candidates.random()
    }

    // --- Data Definitions ---

    private val allTeas: List<TeaVariety> by lazy {
        whiteTeas.map { TeaVariety(it, WHITE) } +
            greenTeasChinese.map { TeaVariety(it, GREEN, CHINESE) } +
            greenTeasJapanese.map { TeaVariety(it, GREEN, JAPANESE) } +
            yellowTeas.map { TeaVariety(it, YELLOW) } +
            blackTeas.map { TeaVariety(it, BLACK) } +
            oolongTeasAnxi.map { TeaVariety(it, OOLONG, ANXI) } +
            oolongTeasYancha.map { TeaVariety(it, OOLONG, YANCHA) } +
            oolongTeasTaiwanese.map { TeaVariety(it, OOLONG, TAIWANESE) } +
            oolongTeasDancong.map { TeaVariety(it, OOLONG, DANCONG) } +
            puerFactory.flatMap { tea ->
                puerPermutations.map { permutationString ->
                    TeaVariety(String.format(permutationString, tea), PUER, FACTORY)
                }
            } +
            puerBoutique.flatMap { tea ->
                puerPermutations.map { permutationString ->
                    TeaVariety(String.format(permutationString, tea), PUER, BOUTIQUE)
                }
            } +
            nonPuHeicha.map { TeaVariety(it, HEICHA) }
    }

    // Modifiers
    private val puerPermutations = listOf(
        "a young sheng pu'er from %s",
        "a semi-aged sheng pu'er from %s",
        "an aged sheng pu'er from %s",
        "a young shu pu'er from %s",
        "an aged shu pu'er from %s",
    )

    // Tea Lists
    private val whiteTeas = listOf(
        "Fuding Baihao Yinzhen",
        "Zhenghe Baihao Yinzhen",
        "Fuding Baimudan",
        "Zhenghe Baimudan",
        "green Shoumei",
        "browned Shoumei",
        "aged Shoumei",
        "Gongmei",
        "Jinggu silver needle",
        "Yue Guang Bai",
        "Xiang Shui Bai Cha",
        "non-standard white tea",
    )

    private val greenTeasChinese = listOf(
        "Longjing",
        "Biluochun",
        "Huangshan Maofeng",
        "Lu'an Guapian",
        "Xinyang Maojian",
        "Taiping Houkui",
        "Anji Bai Cha",
        "Zhuyeqing",
        "Lushan Yunwu",
        "Jasmine green tea",
        "Enshi Yulu",
        "Ganlu",
        "Zi Sun",
        "Xiang Ya",
    )

    private val greenTeasJapanese = listOf(
        "Gyokuro",
        "Sencha",
        "Kamairicha",
        "Genmaicha",
        "Hojicha",
        "Kukicha",
        "Matcha",
    )

    private val yellowTeas = listOf(
        "Junshan Yinzhen",
        "Huoshan Huangya",
        "Huoshan Huangcha",
        "Mengding Huangya",
        "Mengding Huangcha",
        "Mengding Huangdacha",
    )

    private val oolongTeasAnxi = listOf(
        "Qingxiang Tieguanyin",
        "Chuangtong Tieguanyin",
        "aged Tieguanyin",
        "high-roast Tieguanyin",
        "Anxi Huang Jin Gui",
        "Anxi Bai Ji Guan",
        "Anxi Cui Yu",
        "Jin Guan Yin",
        "Foshou",
        "Anxi Ben Shan",
        "Anxi Mao Xie",
        "Zhang Ping Shui Xian",
    )

    private val oolongTeasTaiwanese = listOf(
        "Gaoshan oolong",
        "Gaoleng oolong",
        "Dong Ding",
        "Jin Xuan",
        "Dongfang Meiren",
        "Baozhong",
        "Taiwanese Tieguanyin",
        "Cui Yu",
        "Si Ji Chun",
        "Alishan",
        "Li Shan",
        "Shan Lin Xi",
        "Yushan",
        "GABA oolong",
        "hong oolong",
    )

    private val oolongTeasYancha = listOf(
        "Shui Xian",
        "Laocong Shui Xian",
        "Rougui",
        "Tieluohan",
        "Da Hong Pao",
        "Qilan",
        "Bai Ji Guan",
        "Mei Zhan",
        "Lao Shu Mei Zhan",
        "aged yancha",
        "Bai Hua Kai",
        "Gui Zhi Yun",
        "Lan Shui",
        "Dan Gui",
        "Jin Mu Dan",
        "Shi Ru",
        "Su Xin Lan",
        "Chun Gui",
        "Huang Guan Yin",
        "Que She",
        "Huang Qi",
        "Bei Dou",
        "Jin Guan Yin",
        "Qian Li Xiang",
        "Ban Tian Yao",
        "Huang Mei Gui",
        "something expensive from the San Keng Liang Jian",
    )

    private val oolongTeasDancong = listOf(
        "Huang Zhi Xiang",
        "Zhi Lan Xiang",
        "Yu Lan Xiang",
        "Mi Lan Xiang",
        "Ya Shi Xiang",
        "Xing Ren Xiang",
        "Jiang Hua Xiang",
        "Rou Gui Xiang",
        "Gui Hua Xiang",
        "Ye Lai Xiang",
        "Mo Li Xiang",
        "You Hua Xiang",
        "Chen Hua Xiang",
        "Yang Mei Xiang",
        "Fu Zi Xiang",
        "Huang Cha Xiang",
    )

    private val blackTeas = listOf(
        "Qimen hongcha",
        "smoked Zhengshan Xiaozhong",
        "unsmoked Zhengshan Xiaozhong",
        "Jin Jun Mei",
        "Dian Hong",
        "Yingdehong",
        "Jinhou",
        "Bailin Gongfu",
        "Jiu Qu Hong Mei",
    )

    private val puerFactory = listOf(
        "from Menghai Tea Factory",
        "from Xiaguan",
        "from Liming Tea Factory",
        "from Kungming Tea Factory",
        "from Langhe Tea Factory",
        "from Haiwan Tea Factory",
        "from a small factory",
    )

    private val puerBoutique = listOf(
        "Guafengzhai",
        "Mansa",
        "Yiwu",
        "Tianmenshan",
        "Gaoshanzhai",
        "Manzhuan",
        "Mangzhi",
        "Gedeng",
        "Youle",
        "Huazhuliangzi",
        "Naka",
        "Mengsong",
        "Nannuo",
        "Pasha/Lunan",
        "Nannuo",
        "Hekai",
        "Laobanzhang",
        "Lao Man E tian cha",
        "Lao Man E ku cha",
        "Bulang",
        "Bada",
        "Jingmai",
        "Bangwai",
        "Kunlu",
        "Jinggu",
        "Ai Lao",
        "Wuliang",
        "Kuzhushan",
        "Xibanshan",
        "Dongbanshan",
        "Bingdao Laozhai",
        "Dijie",
        "Bawai",
        "Nanpo",
        "Nuowu",
        "Xigui",
        "Bangdong",
        "Yongde Daxueshan",
        "Mengku Daxueshan",
        "Lincang Daxueshan",
        "Baiyingshan",
    )

    private val nonPuHeicha = listOf(
        "Liu Bao",
        "Fuzhuan",
        "Hei Zhuan",
        "Hua Juan Cha",
        "Xiang Jian",
        "Qu Jiangbo Pian",
        "Sichuan heicha",
        "Anhui heicha",
        "Japanese heicha",
    )
}
