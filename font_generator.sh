#!/bin/bash

# Custom font generator for Soroit
#
# Copyright (c) 2024 omonomo
#
# [Original Script]
# Ricty Generator (ricty_generator-4.1.1.sh)
#
# Copyright (c) 2011-2017 Yasunori Yusa
# All rights reserved.
# (https://rictyfonts.github.io)


# ログをファイル出力させる場合は有効にする (<< "#LOG" をコメントアウトさせる)
<< "#LOG"
LOG_OUT=/tmp/font_generator.log
LOG_ERR=/tmp/font_generator_err.log
exec 1> >(tee -a $LOG_OUT)
exec 2> >(tee -a $LOG_ERR)
#LOG

font_familyname="Soroit"
font_familyname_suffix=""

font_version="0.1.0"
vendor_id="PfEd"

tmpdir_name="font_generator_tmpdir" # 一時保管フォルダ名
nopatchdir_name="nopatchFonts" # パッチ前フォントの保存フォルダ名
nopatchsetdir_name="" # 各パッチ前フォントの設定と font_generator 情報の保存フォルダ名
fileDataName="fileData" # font_generator と 設定ファイルのハッシュ値を保存するファイル名

# グリフ保管アドレス
num_mod_glyphs="4" # -t オプションで改変するグリフ数
address_store_start="64336" # 0ufb50 保管したグリフの最初のアドレス
address_store_g=${address_store_start} # 保管したgアドレス
address_store_b_diagram=$((address_store_g + 1)) # 保管した▲▼■アドレス
address_store_underline=$((address_store_b_diagram + 3)) # 保管した下線アドレス
address_store_mod=$((address_store_underline + 3)) # 保管したDQVZアドレス
address_store_braille=$((address_store_mod + num_mod_glyphs * 6)) # 保管した点字アドレス
address_store_zero=$((address_store_braille + 256)) # 保管したスラッシュ無し0アドレス
address_store_visi_latin=$((address_store_zero + 6)) # latinフォントの保管した識別性向上アドレス ⁄|
address_store_visi_kana=$((address_store_visi_latin + 2)) # 仮名フォントの保管した識別性向上アドレス ゠ - ➓
address_store_visi_kanzi=$((address_store_visi_kana + 26)) # 漢字フォントの保管した識別性向上アドレス 〇 - 口
address_store_line=$((address_store_visi_kanzi + 9)) # 保管した罫線アドレス
address_store_arrow=$((address_store_line + 32)) # 保管した矢印アドレス
address_store_vert=$((address_store_arrow + 4)) # 保管した縦書きアドレス(縦書きの縦線無し（ - 縦書きの縦線無し⁉)
address_store_zenhan=$((address_store_vert + 109)) # 保管した全角半角アドレス(！゠⁉)
address_store_d_hyphen=$((address_store_zenhan + 172)) # 保管した縦書き゠アドレス
address_store_otherspace=$((address_store_d_hyphen + 1)) # 保管したその他のスペースアドレス
address_store_liga=$((address_store_otherspace + 2)) # 保管したリガチャアドレス
address_store_end=$((address_store_liga + 2 - 1)) # 保管したグリフの最終アドレス

address_vert_start="1114181" # 合成後のvert置換の先頭アドレス (リガチャなし)
lookupIndex_liga_end="0" # リガチャ用caltの最終lookupナンバー (リガチャなし)
address_vert_start_liga="1114182" # 合成後のvert置換の先頭アドレス (リガチャあり)
lookupIndex_liga_end_liga="77" # リガチャ用caltの最終lookupナンバー (リガチャあり)
lookupIndex_calt="18" # caltテーブルのlookupナンバー (リガチャなし、lookupの種類を増やした場合変更)
num_calt_lookups="20" # caltのルックアップ数 (calt_table_makerでlookupを変更した場合、それに合わせる。table_modificatorも変更すること)
address_init() {
    address_vert_bracket=${address_vert_start} # vert置換アドレス （
    address_vert_X=$((address_vert_bracket + 109)) # vert置換アドレス ✂
    address_vert_dh=$((address_vert_X + 3)) # vert置換アドレス ゠
    address_vert_mm=$((address_vert_dh + 27)) # vert置換アドレス ㍉
    address_vert_kabu=$((address_vert_mm + 333)) # vert置換アドレス ㍿
    address_vert_end=$((address_vert_kabu + 7 - 1)) # vert置換の最終アドレス ㋿

    address_calt_start=$((address_vert_end + 1)) # calt置換の先頭アドレス
    address_calt_AL=${address_calt_start} # calt置換アドレス(左に移動した A)
    address_calt_AR=$((address_calt_AL + 239)) # calt置換アドレス(右に移動した A)
    address_calt_figure=$((address_calt_AR + 239)) # calt置換アドレス(桁区切り付きの数字)
    address_calt_barD=$((address_calt_figure + 40)) # calt置換アドレス(下に移動した |)
    address_calt_hyphenL=$((address_calt_barD + 9)) # calt置換アドレス(左に移動した *、数を変更した場合スロットの確保数を変更すること)
    address_calt_hyphenR=$((address_calt_hyphenL + 30)) # calt置換アドレス(右に移動した *)
    address_calt_end=$((address_calt_hyphenR + 30 - 1)) # calt置換の最終アドレス (右上に移動した :)
    address_calt_barDLR="24" # calt置換アドレス(左右に移動した * から、左右に移動した | までの増分)

    address_ss_start=$((address_calt_end + 1)) # ss置換の先頭アドレス
    address_ss_space=${address_ss_start} # ss置換アドレス(全角スペース)
    address_ss_figure=$((address_ss_space + 3)) # ss置換アドレス(桁区切り付きの数字)
    address_ss_vert=$((address_ss_figure + 50)) # ss置換の縦書き全角アドレス(縦書きの（)
    address_ss_zenhan=$((address_ss_vert + 109)) # ss置換の横書き全角半角アドレス(！)
    address_ss_braille=$((address_ss_zenhan + 172)) # ss置換の点字アドレス
    address_ss_visibility=$((address_ss_braille + 256)) # ss置換の識別性向上アドレス(/)
    address_ss_mod=$((address_ss_visibility + 46)) # ss置換のDQVZアドレス
    address_ss_line=$((address_ss_mod + num_mod_glyphs * 6)) # ss置換の罫線アドレス
    address_ss_arrow=$((address_ss_line + 32)) # ss置換の矢印アドレス
    address_ss_zero=$((address_ss_arrow + 4)) # ss置換のスラッシュ無し0アドレス
    address_ss_otherspace=$((address_ss_zero + 10)) # ss置換のその他のスペースアドレス
    address_ss_liga=$((address_ss_otherspace + 2)) # ss置換のリガチャアドレス
    address_ss_ambiguous=$((address_ss_liga + 2)) # ss置換のあいまい文字アドレス
    address_ss_end=$((address_ss_ambiguous + 115 - 1)) # ss置換の最終アドレス
    num_ss_glyphs_former=$((address_ss_braille - address_ss_start)) # ss置換のグリフ数(点字の前まで)
    num_ss_glyphs_latter=$((address_ss_end + 1 - address_ss_braille)) # ss置換のグリフ数(点字から後)
    num_ss_glyphs=$((address_ss_end + 1 - address_ss_start)) # ss置換の総グリフ数

    lookupIndex_replace=$((lookupIndex_calt + num_calt_lookups)) # 単純置換のlookupナンバー
    num_replace_lookups="11" # 単純置換のルックアップ数 (lookupの数を変えた場合はcalt_table_makerも変更すること)

    lookupIndex_ss=$((lookupIndex_replace + num_replace_lookups)) # ssテーブルのlookupナンバー
    num_ss_lookups="12" # ssのルックアップ数 (lookupの数を変えた場合はtable_modificatorも変更すること)
}
# 著作権
copyright="Copyright (c) 2024 omonomo\n\n"
copyright="${copyright}\" + \"[Source Code Pro]\n© 2023 Adobe (http://www.adobe.com/)\n\n"
copyright="${copyright}\" + \"[Hasklig]\nIan Tuomi 2014-2015.\n\n"
copyright="${copyright}\" + \"[Inconsolata]\nCopyright 2006 The Inconsolata Project Authors (https://github.com/cyrealtype/Inconsolata)\n\n"
copyright="${copyright}\" + \"[Circle M+]\nCopyright(c) 2020 M+ FONTS PROJECT, itouhiro\n\n"
copyright="${copyright}\" + \"[BIZ UDGothic]\nCopyright 2022 The BIZ UDGothic Project Authors (https://github.com/googlefonts/morisawa-biz-ud-gothic)\n\n"
copyright="${copyright}\" + \"[NINJAL Hentaigana]\nCopyright(c) National Institute for Japanese Language and Linguistics (NINJAL), 2018.\n\n"
copyright_nerd_fonts="[Symbols Nerd Font]\nCopyright (c) 2016, Ryan McIntyre\n\n"
copyright_license="SIL Open Font License Version 1.1 (http://scripts.sil.org/ofl)"

em_ascent1024="827" # em値1024用 ※ win_ascent - (設定したい typo_linegap) / 2 が適正っぽい
em_descent1024="197" # win_descent - (設定したい typo_linegap) / 2 が適正っぽい
typo_ascent1024="${em_ascent1024}" # typo_ascent + typo_descent = em値にしないと縦書きで文字間隔が崩れる
typo_descent1024="${em_descent1024}" # 縦書きに対応させない場合、linegap = 0で typo、win、hhea 全てを同じにするのが無難
 #typo_linegap1024="224" # 本来設定したい値 (win_ascent + win_descent = typo_ascent + typo_descent + typo_linegap)
typo_linegap1024="150" # 数値が大きすぎると Excel (Windows版、Mac版については不明) で文字コード 80h 以上 (おそらく) の文字がずれる
win_ascent1024="939"
win_descent1024="309"
hhea_ascent1024="${win_ascent1024}"
hhea_descent1024="${win_descent1024}"
hhea_linegap1024="0"

# em値変更でのY座標のズレ修正用
move_y_em_revise="-10" # Y座標移動量

# NerdFonts 用
move_y_nerd="30" # 全体Y座標移動量

scale_height_pl="120.7" # PowerlineY座標拡大率
scale_height_pl2="121.9" # PowerlineY座標拡大率 2
scale_height_block="89" # ボックス要素Y座標拡大率
scale_height_pl_revise="100" # 画面表示のずれを修正するための拡大率
center_height_pl=$((277 + move_y_nerd + move_y_em_revise)) # PowerlineリサイズY座標中心
move_y_pl="18" # PowerlineY座標移動量 (上端から ascent までと 下端から descent までの距離が同じになる移動量)
move_y_pl_revise="-10" # 画面表示のずれを修正するための移動量

scale_pomicons="91" # Pomicons の拡大率
scale_nerd="89" # Pomicons Powerline 以外の拡大率

# 半角から全角に変換する場合の拡大率
scale_hankaku2zenkaku="125"

# 全角から半角に変換する場合の拡大率
scale_zenkaku2hankaku="70"

# 上付き、下付き用
scale_width_super_sub="73" # 基本から作成する上付き・下付き文字のX座標拡大率
scale_height_super_sub="73" # 基本から作成する上付き・下付き文字のY座標拡大率
weight_super_sub="10" # ウェイト調整量
move_y_super="393" # 基本から作成した上付き文字のY座標移動量 (すでにある上付き文字のベースラインのY座標)

center_height_super_sub="213" # 上付き、下付き文字のY座標拡大中心
scale_super_sub2="100" # 上付き、下付き文字の拡大率
move_y_super2="0" # 上付き文字のY座標移動量
move_y_sub="-184" # 下付き文字のY座標移動量

move_y_super_base="100" # ベースフォントの上付き文字Y座標移動量 (Latin フォントとベースラインを合わせる)
move_y_sub_base="0" # ベースフォントの下付き文字Y座標移動量 (Latin フォントとベースラインを合わせる)

# latin 括弧移動量 (ベースフォントと中心を合わせる)
move_y_latin_bracket="47"

# latin アンダーバー移動量
move_y_latin_underbar="36"

# 全角アンダーバー移動量 (Latin フォントと高さを合わせる)
move_y_zenkaku_underbar="-20"

# 縦書き全角記号移動量
move_x_vert_colon="65" # ：；
move_x_vert_bar="67" # ｜
move_x_vert_solidus="42" # ／＼
move_x_vert_math="-13" # ＝－＜＞
move_y_vert_bbar="42" # ￤

# 縦書き全角ラテン小文字移動量
move_y_vert_1="-10"
move_y_vert_2="10"
move_y_vert_3="30"
move_y_vert_4="80"
move_y_vert_5="120"
move_y_vert_6="140"
move_y_vert_7="160"

# オブリーク体 (Transform()) 用
tan_oblique="16" # 傾きの係数 (tanθ * 100)
move_x_oblique="-48" # 移動量 (後の処理で * 100 にする)

# 演算子移動量
move_y_math="0" # 通常
move_y_s_math="0" # 上付き、下付き
move_y_zenkaku_math="31" # ベースフォントの演算子上下移動量 (Latin フォントと高さを合わせる)

# calt用
move_y_calt_separate3="-510" # 3桁区切り表示のY座標
move_y_calt_separate4="452" # 4桁区切り表示のY座標
scale_calt_decimal="93" # 小数の拡大率
calt_init() {
    move_x_calt_colon="0" # : のX座標移動量
    move_y_calt_colon=$((move_y_math + 82)) # : のY座標移動量
    move_y_calt_colon=$(bc <<< "scale=0; ${move_y_calt_colon} * ${scale_height_latin} / 100") # : のY座標移動量
    move_y_calt_colon=$(bc <<< "scale=0; ${move_y_calt_colon} * ${scale_height_hankaku} / 100") # : のY座標移動量
    move_y_calt_bar=$((move_y_math + 56)) # | のY座標移動量
    move_y_calt_bar=$(bc <<< "scale=0; ${move_y_calt_bar} * ${scale_height_latin} / 100") # | のY座標移動量
    move_y_calt_bar=$(bc <<< "scale=0; ${move_y_calt_bar} * ${scale_height_hankaku} / 100") # | のY座標移動量
    move_y_calt_tilde=$((move_y_math + 0)) # ~ のY座標移動量
    move_y_calt_tilde=$(bc <<< "scale=0; ${move_y_calt_tilde} * ${scale_height_latin} / 100") # ~ のY座標移動量
    move_y_calt_tilde=$(bc <<< "scale=0; ${move_y_calt_tilde} * ${scale_height_hankaku} / 100") # ~ のY座標移動量
    move_y_calt_math=$((- move_y_math - 7)) # +-= のY座標移動量
    move_y_calt_math=$(bc <<< "scale=0; ${move_y_calt_math} * ${scale_height_latin} / 100") # *+-= のY座標移動量
    move_y_calt_math=$(bc <<< "scale=0; ${move_y_calt_math} * ${scale_height_hankaku} / 100") # *+-= のY座標移動量
    move_y_calt_colon2="75" # : のY座標移動量 (括弧用)
    move_y_calt_colon2=$(bc <<< "scale=0; ${move_y_calt_colon2} * ${scale_height_latin} / 100") # : のY座標移動量
    move_y_calt_colon2=$(bc <<< "scale=0; ${move_y_calt_colon2} * ${scale_height_hankaku} / 100") # : のY座標移動量
    move_y_calt_bar2="50" # | のY座標移動量 (括弧用)
    move_y_calt_bar2=$(bc <<< "scale=0; ${move_y_calt_bar2} * ${scale_height_latin} / 100") # | のY座標移動量
    move_y_calt_bar2=$(bc <<< "scale=0; ${move_y_calt_bar2} * ${scale_height_hankaku} / 100") # | のY座標移動量
}
# 通常版・Loose版共通
center_height_hankaku="373" # 半角文字Y座標中心
move_x_calt_separate="-512" # 桁区切り表示のX座標移動量 (下書きモードとその他で位置が変わるので注意)
width_zenkaku="1024" # 全角文字幅
width_latin="614" # Latin フォントの em 値を1024に変換したときの文字幅

# 通常版用
scale_width_latin="85" # Latin フォントの半角英数文字の横拡大率
scale_height_latin="97" # Latin フォントの半角英数文字の縦拡大率
move_x_hankaku_latin="-51" # Latin フォント全体のX座標移動量
scale_width_hankaku="100" # 半角英数文字の横拡大率
scale_height_hankaku="100" # 半角英数文字の縦拡大率
scale_width_block="83" # 半角罫線素片・ブロック要素の横拡大率
width_hankaku="512" # 半角文字幅
move_x_calt_latin="16" # ラテン文字のカーニングX座標移動量
move_x_calt_symbol="32" # 記号のカーニングX座標移動量
move_x_hankaku="0" # 半角文字移動量

# Loose 版用
scale_width_latin_loose="95" # Latin フォントの半角英数文字の横拡大率 (Loose 版)
scale_height_latin_loose="101" # Latin フォントの半角英数文字の縦拡大率 (Loose 版)
move_x_hankaku_latin_loose="-19" # Latin フォント全体のX座標移動量 (Loose 版)
scale_width_hankaku_loose="100" # 半角英数文字の横拡大率 (Loose 版)
scale_height_hankaku_loose="100" # 半角英数文字の縦拡大率 (Loose 版)
scale_width_block_loose="94" # 半角罫線素片・ブロック要素の横拡大率 (Loose 版)
width_hankaku_loose="576" # 半角文字幅 (Loose 版)
move_x_calt_latin_loose="18" # ラテン文字のカーニングX座標移動量 (Loose 版)
move_x_calt_symbol_loose="36" # 記号のカーニングX座標移動量 (Loose 版)
move_x_hankaku_loose=$(((width_hankaku_loose - ${width_hankaku}) / 2)) # 半角文字移動量 (Loose 版)

# デバッグ用

 # NerdFonts
 #scale_pomicons="150" # Pomicons の拡大率
 #scale_nerd="150" # その他の拡大率

 # 通常版用
 #scale_width_latin="150" # 半角 Latin フォント英数文字の横拡大率
 #scale_height_latin="50" # 半角 Latin フォント英数文字の縦拡大率

# デバッグ用ここまで

# Set path to command
fontforge_command="fontforge"
ttx_command="ttx"

# Set redirection of stderr
redirection_stderr="/dev/null"

# Set fonts directories used in auto flag
fonts_directories=". ${HOME}/.fonts /usr/local/share/fonts /usr/share/fonts \
${HOME}/Library/Fonts /Library/Fonts \
/c/Windows/Fonts /cygdrive/c/Windows/Fonts"

# Set flags
mode="" # 生成モード

compose_flag="true" # フォントを合成 (既に同じ設定で作成したパッチ前フォントがない)
leaving_tmp_flag="false" # 一時ファイル残す
loose_flag="false" # Loose 版にする
term_flag="false" # あいまい文字等を半角にする
visible_zenkaku_space_flag="true" # 全角スペース可視化
visible_hankaku_space_flag="true" # 半角スペース可視化
improve_visibility_flag="true" # ダッシュ破線化
underline_flag="true" # 全角半角に下線
mod_flag="true" # DVQZ改変
calt_flag="true" # calt対応
ss_flag="false" # ss対応
nerd_flag="true" # Nerd fonts 追加
separator_flag="true" # 桁区切りあり
slashed_zero_flag="true" # 0にスラッシュあり
oblique_flag="true" # オブリーク作成
emoji_flag="true" # 絵文字を減らさない
draft_flag="false" # 下書きモード
patch_flag="true" # パッチを当てる
patch_only_flag="false" # パッチモード
liga_flag="false" # リガチャフラグ

# Set filenames
origin_latin_regular="SourceCodePro-Regular.ttf"
origin_latin_bold="SourceCodePro-Bold.ttf"
origin_latin_regular2="Hasklig-Regular.ttf"
origin_latin_bold2="Hasklig-Bold.ttf"
origin_base_regular="Cyroit-Regular.nopatch.ttf"
origin_base_bold="Cyroit-Bold.nopatch.ttf"
origin_base_regular_loose="CyroitLoose-Regular.nopatch.ttf"
origin_base_bold_loose="CyroitLoose-Bold.nopatch.ttf"
origin_nerd="SymbolsNerdFontMono-Regular.ttf"

modified_latin_generator="modified_latin_generator.pe"
modified_latin_regular="modified-latin-Regular.sfd"
modified_latin_bold="modified-latin-Bold.sfd"
modified_latin_regular2="modified-latin-Regular2.sfd"
modified_latin_bold2="modified-latin-Bold2.sfd"

custom_font_generator="custom_font_generator.pe"

parameter_modificator="parameter_modificator.pe"

oblique_converter="oblique_converter.pe"

modified_nerd_generator="modified_nerd_generator.pe"
modified_nerd="modified-nerd.ttf"
merged_nerd_generator="merged_nerd_generator.pe"

font_patcher="font_patcher.pe"

################################################################################
# Pre-process
################################################################################

# 設定読み込み
settings="settings" # 設定ファイル名
settings_txt=$(find . -maxdepth 1 -name "${settings}.txt" | head -n 1)
if [ -n "${settings_txt}" ]; then
    S=$(grep -m 1 "^FONT_VERSION=" "${settings_txt}") # フォントバージョン
    if [ -n "${S}" ]; then font_version="${S#FONT_VERSION=}"; fi
    S=$(grep -m 1 "^FONT_FAMILYNAME=" "${settings_txt}") # フォントファミリー名
    if [ -n "${S}" ]; then font_familyname="${S#FONT_FAMILYNAME=}"; fi
    S=$(grep -m 1 "^FONT_FAMILYNAME_SUFFIX=" "${settings_txt}") # フォントファミリー名接尾語
    if [ -n "${S}" ]; then font_familyname_suffix="${S#FONT_FAMILYNAME_SUFFIX=}"; fi
    S=$(grep -m 1 "^VENDOR_ID=" "${settings_txt}") # ベンダー ID
    if [ -n "${S}" ]; then vendor_id="${S#VENDOR_ID=}"; fi
    S=$(grep "^COPYRIGHT=" "${settings_txt}") # 著作権
    if [ -n "${S}" ]; then
        copyright="${S//COPYRIGHT=/}";
        copyright="${copyright//
/\\n\\n\" + \"}\n\n";
    fi
    S=$(grep -m 1 "^COPYRIGHT_NERD_FONTS=" "${settings_txt}") # 著作権 (Nerd fonts)
    if [ -n "${S}" ]; then copyright_nerd_fonts="${S#COPYRIGHT_NERD_FONTS=}\n\n"; fi
    S=$(grep -m 1 "^COPYRIGHT_LICENSE=" "${settings_txt}") # ライセンス
    if [ -n "${S}" ]; then copyright_license="${S#COPYRIGHT_LICENSE=}"; fi
    S=$(grep -m 1 "^SCALE_WIDTH_HANKAKU=" "${settings_txt}") # 通常版の半角文字 横幅拡大率
    if [ -n "${S}" ]; then scale_width_hankaku="${S#SCALE_WIDTH_HANKAKU=}"; fi
    S=$(grep -m 1 "^SCALE_HEIGHT_HANKAKU=" "${settings_txt}") # 通常版の半角文字 高さ拡大率
    if [ -n "${S}" ]; then scale_height_hankaku="${S#SCALE_HEIGHT_HANKAKU=}"; fi
    S=$(grep -m 1 "^SCALE_WIDTH_HANKAKU_LOOSE=" "${settings_txt}") # Loose 版の半角文字 横幅拡大率
    if [ -n "${S}" ]; then scale_width_hankaku_loose="${S#SCALE_WIDTH_HANKAKU_LOOSE=}"; fi
    S=$(grep -m 1 "^SCALE_HEIGHT_HANKAKU_LOOSE=" "${settings_txt}") # Loose 版の半角文字 高さ拡大率
    if [ -n "${S}" ]; then scale_height_hankaku_loose="${S#SCALE_HEIGHT_HANKAKU_LOOSE=}"; fi
    S=$(grep -m 1 "^MOVE_X_KERN_LATIN=" "${settings_txt}") # 通常版のラテン文字 カーニング横移動量
    if [ -n "${S}" ]; then move_x_calt_latin="${S#MOVE_X_KERN_LATIN=}"; fi
    S=$(grep -m 1 "^MOVE_X_KERN_SYMBOL=" "${settings_txt}") # 通常版の記号 カーニング横移動量
    if [ -n "${S}" ]; then move_x_calt_symbol="${S#MOVE_X_KERN_SYMBOL=}"; fi
    S=$(grep -m 1 "^MOVE_X_KERN_LATIN_LOOSE=" "${settings_txt}") # Loose 版のラテン文字 カーニング横移動量
    if [ -n "${S}" ]; then move_x_calt_latin_loose="${S#MOVE_X_KERN_LATIN_LOOSE=}"; fi
    S=$(grep -m 1 "^MOVE_X_KERN_SYMBOL_LOOSE=" "${settings_txt}") # Loose 版の記号 カーニング横移動量
    if [ -n "${S}" ]; then move_x_calt_symbol_loose="${S#MOVE_X_KERN_SYMBOL_LOOSE=}"; fi
    S=$(grep -m 1 "^TAN_OBLIQUE=" "${settings_txt}") # オブリーク体の傾き
    if [ -n "${S}" ]; then tan_oblique="${S#TAN_OBLIQUE=}"; fi
    S=$(grep -m 1 "^MOVE_X_OBLIQUE=" "${settings_txt}") # オブリーク体横移動量
    if [ -n "${S}" ]; then move_x_oblique="${S#MOVE_X_OBLIQUE=}"; fi
    S=$(grep -m 1 "^SCALE_HEIGHT_POWERLINE=" "${settings_txt}") # Powerline 高さ拡大率
    if [ -n "${S}" ]; then scale_height_pl_revise="${S#SCALE_HEIGHT_POWERLINE=}"; fi
    S=$(grep -m 1 "^MOVE_Y_POWERLINE=" "${settings_txt}") # Powerline 縦移動量
    if [ -n "${S}" ]; then move_y_pl_revise="${S#MOVE_Y_POWERLINE=}"; fi
    S=$(grep -m 1 "^SCALE_DECIMAL=" "${settings_txt}") # 小数拡大率
    if [ -n "${S}" ]; then scale_calt_decimal="${S#SCALE_DECIMAL=}"; fi
    S=$(grep -m 1 "^MOVE_Y_MATH=" "${settings_txt}") # 通常の演算子縦移動量
    if [ -n "${S}" ]; then move_y_math="${S#MOVE_Y_MATH=}"; fi
    S=$(grep -m 1 "^MOVE_Y_S_MATH=" "${settings_txt}") # 上付き、下付きの演算子縦移動量
    if [ -n "${S}" ]; then move_y_s_math="${S#MOVE_Y_S_MATH=}"; fi
fi

# Powerline の Y座標移動量
move_y_pl=$((move_y_pl + move_y_pl_revise)) # 実際の移動量
move_y_pl2=$((move_y_pl + 3)) # 実際の移動量 2

# Powerline、ボックス要素の Y座標拡大率
scale_height_pl=$(bc <<< "scale=1; ${scale_height_pl} * ${scale_height_pl_revise} / 100") # PowerlineY座標拡大率
scale_height_pl2=$(bc <<< "scale=1; ${scale_height_pl2} * ${scale_height_pl_revise} / 100") # PowerlineY座標拡大率 2
scale_height_block=$(bc <<< "scale=1; ${scale_height_block} * ${scale_height_pl_revise} / 100") # ボックス要素Y座標拡大率

# オブリーク体用
move_x_oblique=$((move_x_oblique * 100)) # Transform()用 (移動量 * 100)

# Print information message
cat << _EOT_

----------------------------
Custom font generator
Font version: ${font_version}
----------------------------

_EOT_

option_check() {
  if [ -n "${mode}" ]; then # -Pp のうち2個以上含まれていたら終了
    echo "Illegal option"
    exit 1
  fi
}

# Define displaying help function
font_generator_help()
{
    echo "Usage: font_generator.sh [options] auto"
    echo "       font_generator.sh [options] [font1]-{Regular,Bold}.ttf [font2]-{regular,bold}.ttf ..."
    echo ""
    echo "Options:"
    echo "  -h                     Display this information"
    echo "  -V                     Display version number"
    echo "  -x                     Cleaning temporary files" # 一時作成ファイルの消去のみ
    echo "  -X                     Cleaning temporary files and saved nopatch fonts" # 一時作成ファイルとパッチ前フォントの消去のみ
    echo "  -f /path/to/fontforge  Set path to fontforge command"
    echo "  -v                     Enable verbose mode (display fontforge's warning)"
    echo "  -l                     Leave (do NOT remove) temporary files"
    echo "  -N string              Set fontfamily (\"string\")"
    echo "  -n string              Set fontfamily suffix (\"string\")"
    echo "  -w                     Set the ratio of hankaku to zenkaku characters to 9:16"
    echo "  -a                     Set neutral and ambiguous characters to hankaku (excluding private use areas)"
    echo "  -L                     Enable ligatures"
    echo "  -Z                     Disable visible zenkaku space"
    echo "  -z                     Disable visible hankaku space"
    echo "  -u                     Disable zenkaku hankaku underline"
    echo "  -b                     Disable glyphs with improved visibility"
    echo "  -t                     Disable modified D,Q,V and Z"
    echo "  -O                     Disable slashed zero"
    echo "  -s                     Disable thousands separator"
    echo "  -c                     Disable calt feature (excluding ligatures)"
    echo "  -e                     Disable add Nerd fonts"
    echo "  -o                     Disable generate oblique style fonts"
    echo "  -j                     Reduce the number of emoji glyphs"
    echo "  -S                     Enable ss feature"
    echo "  -d                     Enable draft mode (skip time-consuming processes)"
    echo "  -P                     End just before patching"
    echo "  -p                     Run font patch only"
}

# Get options
while getopts hVxXf:vlN:n:waLZzubtOsceojSdPp OPT
do
    case "${OPT}" in
        "h" )
            font_generator_help
            exit 0
            ;;
        "V" )
            exit 0
            ;;
        "x" )
            echo "Option: Cleaning temporary files"
            echo "Remove temporary files"
            rm -rf ${tmpdir_name}.*
            exit 0
            ;;
        "X" )
            echo "Option: Cleaning temporary files and saved nopatch fonts"
            echo "Remove temporary files"
            rm -rf ${tmpdir_name}.*
            echo "Remove nopatch fonts"
            rm -rf "${nopatchdir_name}"
            exit 0
            ;;
        "f" )
            echo "Option: Set path to fontforge command: ${OPTARG}"
            fontforge_command="${OPTARG}"
            ;;
        "v" )
            echo "Option: Enable verbose mode"
            redirection_stderr="/dev/stderr"
            ;;
        "l" )
            echo "Option: Leave (do NOT remove) temporary files"
            leaving_tmp_flag="true"
            ;;
        "N" )
            echo "Option: Set fontfamily: ${OPTARG}"
            font_familyname=${OPTARG// /}
            ;;
        "n" )
            echo "Option: Set fontfamily suffix: ${OPTARG}"
            font_familyname_suffix=${OPTARG// /}
            ;;
        "w" )
            echo "Option: Set the ratio of hankaku to zenkaku characters to 9:16"
            loose_flag="true"
            origin_base_regular="${origin_base_regular_loose}"
            origin_base_bold="${origin_base_bold_loose}"
            scale_width_latin=${scale_width_latin_loose} # Latin フォントの半角英数文字の横拡大率
            scale_height_latin=${scale_height_latin_loose} # Latin フォントの半角英数文字の縦拡大率
            move_x_hankaku_latin=${move_x_hankaku_latin_loose} # Latin フォント全体のX座標移動量
            scale_width_hankaku=${scale_width_hankaku_loose} # 半角英数文字の横拡大率
            scale_height_hankaku=${scale_height_hankaku_loose} # 半角英数文字の縦拡大率
            scale_width_block=${scale_width_block_loose} # 半角罫線素片・ブロック要素の横拡大率
            width_hankaku=${width_hankaku_loose} # 半角文字幅
            move_x_hankaku=${move_x_hankaku_loose} # 半角文字移動量
            move_x_calt_latin=${move_x_calt_latin_loose} # ラテン文字のX座標移動量
            move_x_calt_symbol=${move_x_calt_symbol_loose} # 記号のX座標移動量
            ;;
        "a" )
            echo "Option: Set neutral and ambiguous characters to hankaku (excluding private use areas)"
            term_flag="true"
            ;;
        "L" )
            echo "Option: Enable ligatures"
            liga_flag="true"
            address_vert_start=${address_vert_start_liga} # 合成後のvert置換の先頭アドレス (リガチャあり)
            lookupIndex_liga_end=${lookupIndex_liga_end_liga} # リガチャ用caltの最終lookupナンバー (リガチャあり)
            lookupIndex_calt=$((lookupIndex_calt + lookupIndex_liga_end)) # caltテーブルのlookupナンバー (リガチャあり)
            ;;
        "Z" )
            echo "Option: Disable visible zenkaku space"
            visible_zenkaku_space_flag="false"
            ;;
        "z" )
            echo "Option: Disable visible hankaku space"
            visible_hankaku_space_flag="false"
            ;;
        "u" )
            echo "Option: Disable zenkaku hankaku underline"
            if [ "${ss_flag}" = "true" ]; then
                echo "Can't be disabled"
            else
                underline_flag="false"
            fi
            ;;
        "b" )
            echo "Option: Disable glyphs with improved visibility"
            if [ "${ss_flag}" = "true" ]; then
                echo "Can't be disabled"
            else
                improve_visibility_flag="false"
            fi
            ;;
        "t" )
            echo "Option: Disable modified D,Q,V and Z"
            mod_flag="false"
            ;;
        "O" )
            echo "Option: Disable slashed zero"
            slashed_zero_flag="false"
            ;;
        "s" )
            echo "Option: Disable thousands separator"
            separator_flag="false"
            ;;
        "c" )
            echo "Option: Disable calt feature (excluding ligatures)"
            if [ "${ss_flag}" = "true" ]; then
                echo "Can't be disabled"
            else
                calt_flag="false"
            fi
            ;;
        "e" )
            echo "Option: Disable add Nerd fonts"
            nerd_flag="false"
            ;;
        "o" )
            echo "Option: Disable generate oblique style fonts"
            oblique_flag="false"
            ;;
        "j" )
            echo "Option: Reduce the number of emoji glyphs"
            emoji_flag="false"
            ;;
        "S" )
            echo "Option: Enable ss feature"
            visible_zenkaku_space_flag="false"
            visible_hankaku_space_flag="false"
            underline_flag="true"
            improve_visibility_flag="true"
 #            underline_flag="false" # デフォルトで下線無しにする場合
            mod_flag="false"
            slashed_zero_flag="true"
            calt_flag="true"
            separator_flag="false"
            ss_flag="true"
            ;;
        "d" )
            echo "Option: Enable draft mode (skip time-consuming processes)"
            draft_flag="true"
            oblique_flag="false"
            ;;
        "P" )
            echo "Option: End just before patching"
            option_check
            mode="-P"
            patch_flag="false"
            patch_only_flag="false"
            ;;
        "p" )
            echo "Option: Run font patch only"
            option_check
            mode="-p"
            patch_flag="true"
            patch_only_flag="true"
            ;;
        * )
            font_generator_help
            exit 1
            ;;
    esac
done
echo

address_init
calt_init
shift $(($OPTIND - 1))

# Get input fonts
if [ "${patch_only_flag}" = "false" ]; then
    if [ $# -eq 1 -a "$1" = "auto" ]; then
        # Check existance of directories
        tmp=""
        for i in $fonts_directories
        do
            [ -d "${i}" ] && tmp="${tmp} ${i}"
        done
        fonts_directories=$tmp
        # Search latin fonts
        input_latin_regular=$(find $fonts_directories -follow -name "${origin_latin_regular}" | head -n 1)
        input_latin_bold=$(find $fonts_directories -follow -name "${origin_latin_bold}" | head -n 1)
        if [ -z "${input_latin_regular}" -o -z "${input_latin_bold}" ]; then
            echo "Error: ${origin_latin_regular} and/or ${origin_latin_bold} not found" >&2
            exit 1
        fi
        # Search latin fonts 2
        input_latin_regular2=$(find $fonts_directories -follow -name "${origin_latin_regular2}" | head -n 1)
        input_latin_bold2=$(find $fonts_directories -follow -name "${origin_latin_bold2}" | head -n 1)
        if [ -z "${input_latin_regular2}" -o -z "${input_latin_bold2}" ]; then
            echo "Error: ${origin_latin_regular2} and/or ${origin_latin_bold2} not found" >&2
            exit 1
        fi
        # Search base fonts
        input_base_regular=$(find $fonts_directories -follow -iname "${origin_base_regular}" | head -n 1)
        input_base_bold=$(find $fonts_directories -follow -iname "${origin_base_bold}"    | head -n 1)
        if [ -z "${input_base_regular}" -o -z "${input_base_bold}" ]; then
            echo "Error: ${origin_base_regular} and/or ${origin_base_bold} not found" >&2
            exit 1
        fi
        if [ ${nerd_flag} = "true" ]; then
            # Search nerd fonts
            input_nerd=$(find $fonts_directories -follow -iname "${origin_nerd}" | head -n 1)
            if [ -z "${input_nerd}" ]; then
                echo "Error: ${origin_nerd} not found" >&2
                exit 1
            fi
        fi
    elif ( [ ${nerd_flag} = "false" ] && [ $# -eq 6 ] ) || ( [ ${nerd_flag} = "true" ] && [ $# -eq 7 ] ); then
        # Get arguments
        input_latin_regular=$1
        input_latin_bold=$2
        input_latin_regular2=$3
        input_latin_bold2=$4
        input_base_regular=$5
        input_base_bold=$6
        if [ ${nerd_flag} = "true" ]; then
            input_nerd=$7
        fi
        # Check existance of files
        if [ ! -r "${input_latin_regular}" ]; then
            echo "Error: ${input_latin_regular} not found" >&2
            exit 1
        elif [ ! -r "${input_latin_bold}" ]; then
            echo "Error: ${input_latin_bold} not found" >&2
            exit 1
        elif [ ! -r "${input_latin_regular2}" ]; then
            echo "Error: ${input_latin_regular2} not found" >&2
            exit 1
        elif [ ! -r "${input_latin_bold2}" ]; then
            echo "Error: ${input_latin_bold2} not found" >&2
            exit 1
        elif [ ! -r "${input_base_regular}" ]; then
            echo "Error: ${input_base_regular} not found" >&2
            exit 1
        elif [ ! -r "${input_base_bold}" ]; then
            echo "Error: ${input_base_bold} not found" >&2
            exit 1
        elif [ ${nerd_flag} = "true" ] && [ ! -r "${input_nerd}" ]; then
            echo "Error: ${input_nerd} not found" >&2
            exit 1
        fi
        # Check filename
        [ "$(basename $input_latin_regular)" != "${origin_latin_regular}" ] &&
            echo "Warning: ${input_latin_regular} does not seem to be ${origin_latin_regular}" >&2
        [ "$(basename $input_latin_bold)" != "${origin_latin_bold}" ] &&
            echo "Warning: ${input_latin_bold} does not seem to be ${origin_latin_bold}" >&2
        [ "$(basename $input_latin_regular2)" != "${origin_latin_regular2}" ] &&
            echo "Warning: ${input_latin_regular2} does not seem to be ${origin_latin_regular2}" >&2
        [ "$(basename $input_latin_bold2)" != "${origin_latin_bold2}" ] &&
            echo "Warning: ${input_latin_bold2} does not seem to be ${origin_latin_bold2}" >&2
        [ "$(basename $input_base_regular)" != "${origin_base_regular}" ] &&
            echo "Warning: ${input_base_regular} does not seem to be ${origin_base_regular}" >&2
        [ "$(basename $input_base_bold)" != "${origin_base_bold}" ] &&
            echo "Warning: ${input_base_bold} does not seem to be ${origin_base_bold}" >&2
        [ ${nerd_flag} = "true" ] && [ "$(basename $input_nerd)" != "${origin_nerd}" ] &&
            echo "Warning: ${input_nerd} does not seem to be ${origin_nerd}" >&2
    else
        echo "Error: missing arguments"
        echo
        font_generator_help
    fi
fi

# Check fontforge existance
if ! which $fontforge_command > /dev/null 2>&1
then
    echo "Error: ${fontforge_command} command not found" >&2
    exit 1
fi
fontforge_v=$(${fontforge_command} -version)
fontforge_version=$(echo ${fontforge_v} | cut -d ' ' -f2)

# Check ttx existance
if ! which $ttx_command > /dev/null 2>&1
then
    echo "Error: ${ttx_command} command not found" >&2
    exit 1
fi
ttx_version=$(${ttx_command} --version)

# Make temporary directory
if [ -w "/tmp" -a "${leaving_tmp_flag}" = "false" ]; then
    tmpdir=$(mktemp -d /tmp/"${tmpdir_name}".XXXXXX) || exit 2
else
    tmpdir=$(mktemp -d ./"${tmpdir_name}".XXXXXX)    || exit 2
fi

# Remove temporary directory by trapping
if [ "${leaving_tmp_flag}" = "false" ]; then
    trap "if [ -d \"$tmpdir\" ]; then echo 'Remove temporary files'; rm -rf $tmpdir; echo 'Abnormally terminated'; fi; exit 3" HUP INT QUIT
    trap "if [ -d \"$tmpdir\" ]; then echo 'Remove temporary files'; rm -rf $tmpdir; echo 'Abnormally terminated'; fi" EXIT
else
    trap "echo 'Abnormally terminated'; exit 3" HUP INT QUIT
fi
echo

# フォントバージョンにビルドNo追加
buildNo=$(date "+%s")
buildNo=$((buildNo % 315360000 / 60))
buildNo=$(bc <<< "obase=16; ibase=10; ${buildNo}")
font_version="${font_version} (${buildNo})"

################################################################################
# Generate script for modified latin fonts
################################################################################

cat > ${tmpdir}/${modified_latin_generator} << _EOT_
#!$fontforge_command -script

Print("- Generate modified latin fonts -")

# Set parameters
input_list  = ["${input_latin_regular}",    "${input_latin_bold}"]
input_list2  = ["${input_latin_regular2}",    "${input_latin_bold2}"]
output_list = ["${modified_latin_regular}", "${modified_latin_bold}"]
output_list2 = ["${modified_latin_regular2}", "${modified_latin_bold2}"]

# Begin loop of regular and bold
i = 0
while (i < SizeOf(input_list))

# Edit latin font2
    Print("Open " + input_list2[i])
    Open(input_list2[i])
    SelectWorthOutputting()
    UnlinkReference()
    ScaleToEm(${em_ascent1024}, ${em_descent1024})
    SetOS2Value("WinAscent",             ${win_ascent1024}) # WindowsGDI用(この範囲外は描画されない)
    SetOS2Value("WinDescent",            ${win_descent1024})
    SetOS2Value("TypoAscent",            ${typo_ascent1024}) # 組版・DirectWrite用(em値と合わせる)
    SetOS2Value("TypoDescent",          -${typo_descent1024})
    SetOS2Value("TypoLineGap",           ${typo_linegap1024})
    SetOS2Value("HHeadAscent",           ${hhea_ascent1024}) # Mac用
    SetOS2Value("HHeadDescent",         -${hhea_descent1024})
    SetOS2Value("HHeadLineGap",          ${hhea_linegap1024})

    # 使用しないグリフクリア
    Print("Remove not used glyphs")
    SelectWorthOutputting()
    SelectFewer(0u0021) # !
    SelectFewer(0u0024) # $
    SelectFewer(0u0026) # &
    SelectFewer(0u002a) # *
    SelectFewer(0u002b) # +
    SelectFewer(0u002c) # ,
    SelectFewer(0u002d) # -
    SelectFewer(0u002e) # .
    SelectFewer(0u002f) # /
    SelectFewer(0u003a) # :
    SelectFewer(0u003b) # ;
    SelectFewer(0u003c) # <
    SelectFewer(0u003d) # =
    SelectFewer(0u003e) # >
    SelectFewer(0u003f) # ?
    SelectFewer(0u005c) # Backslash
    SelectFewer(0u007c) # |
    if ("${liga_flag}" == "true")
        SelectFewer(0ue100, 0ue129) # リガチャ
        SelectFewer("LIG")
    endif
    Clear(); DetachAndRemoveGlyphs()

    # Clear kerns, position, substitutions
    Print("Clear kerns, position, substitutions")
    RemoveAllKerns()

    lookups = GetLookups("GSUB"); numlookups = SizeOf(lookups); j = 0
    while (j < numlookups)
        if ("${liga_flag}" == "false" || j < 33 || (73 < j && j < 77))
            Print("Remove GSUB_" + lookups[j])
            RemoveLookup(lookups[j])
        endif
        j += 1
    endloop

    lookups = GetLookups("GPOS"); numlookups = SizeOf(lookups); j = 0
    while (j < numlookups)
        Print("Remove GPOS_" + lookups[j])
        RemoveLookup(lookups[j]); j++
    endloop

    # Clear instructions, hints
    Print("Clear instructions, hints")
    SelectWorthOutputting()
    ClearInstrs()
    ClearHints()

    Save("${tmpdir}/" + output_list2[i])

# Open latin font
    Print("Open " + input_list[i])
    Open(input_list[i])
    SelectWorthOutputting()
    UnlinkReference()
    ScaleToEm(${em_ascent1024}, ${em_descent1024})
    SetOS2Value("WinAscent",             ${win_ascent1024}) # WindowsGDI用(この範囲外は描画されない)
    SetOS2Value("WinDescent",            ${win_descent1024})
    SetOS2Value("TypoAscent",            ${typo_ascent1024}) # 組版・DirectWrite用(em値と合わせる)
    SetOS2Value("TypoDescent",          -${typo_descent1024})
    SetOS2Value("TypoLineGap",           ${typo_linegap1024})
    SetOS2Value("HHeadAscent",           ${hhea_ascent1024}) # Mac用
    SetOS2Value("HHeadDescent",         -${hhea_descent1024})
    SetOS2Value("HHeadLineGap",          ${hhea_linegap1024})

# --------------------------------------------------

# 使用しないグリフクリア
    Print("Remove not used glyphs")
    Select(0, 31); Clear(); DetachAndRemoveGlyphs()

# Clear kerns, position, substitutions
    Print("Clear kerns, position, substitutions")
    RemoveAllKerns()

    lookups = GetLookups("GSUB"); numlookups = SizeOf(lookups); j = 0
    while (j < numlookups)
        Print("Remove GSUB_" + lookups[j])
        RemoveLookup(lookups[j])
        j += 1
    endloop

    lookups = GetLookups("GPOS"); numlookups = SizeOf(lookups); j = 0
    while (j < numlookups)
        Print("Remove GPOS_" + lookups[j])
        RemoveLookup(lookups[j]); j++
    endloop

# Clear instructions, hints
    Print("Clear instructions, hints")
    SelectWorthOutputting()
    ClearInstrs()
    ClearHints()

# Merge latin font
    Select(0u0021) # !
    SelectMore(0u0024) # $
    SelectMore(0u0026) # &
    SelectMore(0u002a) # *
    SelectMore(0u002b) # +
    SelectMore(0u002c) # ,
    SelectMore(0u002d) # -
    SelectMore(0u002e) # .
    SelectMore(0u002f) # /
    SelectMore(0u003a) # :
    SelectMore(0u003b) # ;
    SelectMore(0u003c) # <
    SelectMore(0u003d) # =
    SelectMore(0u003e) # >
    SelectMore(0u003f) # ?
    SelectMore(0u005c) # Backslash
    SelectMore(0u007c) # |
    Clear()
    Print("Merge " + output_list2[i])
    MergeFonts("${tmpdir}/" + output_list2[i])

# Proccess before editing
    if ("${draft_flag}" == "false")
        Print("Process before editing")
        SelectWorthOutputting()
        RemoveOverlap()
        CorrectDirection()
    endif

# --------------------------------------------------

# 罫線、ブロックを少し移動
    Print("Move block")
    Select(0u2591, 0u2593)
    Move(20, 0)
    SetWidth(${width_latin})
 #    Print("Move box drawing and block")
 #    Select(0u2500, 0u259f)
 #    Move(0, ${move_y_em_revise})
 #    SetWidth(${width_latin})

    Print("Edit numbers")
# 1 (.a のグリフを加工して置換)
    Select("one.a"); Copy()
    Select("one");   Paste()
    Select(0u2588);  Copy() # Full block
    Select(65552);   Paste() # Temporary glyph
    if (input_list[i] == "${input_latin_regular}")
        Rotate(41); Move(10, 442)
        PasteWithOffset(0, -590)
    else
        Rotate(42); Move(20, 370)
        PasteWithOffset(0, -650)
    endif
    RemoveOverlap()
    Copy()
    Select(0u0031); PasteInto()
    OverlapIntersect()
    SetWidth(${width_latin})
    Select(65552); Clear() # Temporary glyph

    Print("Edit alphabets")
# g (.a のグリフに置換)
    Select("g.a"); Copy();           Select("g"); Paste(); SetWidth(${width_latin})
    Select("uni01F5.a"); Copy();     Select("uni01F5"); Paste(); SetWidth(${width_latin})
    Select("gcircumflex.a"); Copy(); Select("gcircumflex"); Paste(); SetWidth(${width_latin})
    Select("gbreve.a"); Copy();      Select("gbreve"); Paste(); SetWidth(${width_latin})
    Select("gdotaccent.a"); Copy();  Select("gdotaccent"); Paste(); SetWidth(${width_latin})
    Select("uni0123.a"); Copy();     Select("uni0123"); Paste(); SetWidth(${width_latin})
    Select("gcaron.a"); Copy();      Select("gcaron"); Paste(); SetWidth(${width_latin})
    Select("uni1E21.a"); Copy();     Select("uni1E21"); Paste(); SetWidth(${width_latin})

# l (.a のグリフを加工して置換)
    Select(0u2588); Copy() # Full block
    Select(65552);  Paste() # Temporary glyph
    Move(0, 600)
    PasteWithOffset(0, -1025)
    if (input_list[i] == "${input_latin_regular}")
        PasteWithOffset(303, 0)
    else
        PasteWithOffset(264, 0)
    endif
    RemoveOverlap()
    Copy()
    Select("l.a")
    SelectMore("lacute.a")
    SelectMore("lcaron.a")
    SelectMore("uni013C.a")
    SelectMore("uni1E37.a")
    SelectMore("uni1E39.a")
    SelectMore("uni1E3B.a")
    SelectMore("lslash.a")
    SelectMore("uni026B.a")
    SelectMore("uni026C.a")
    PasteInto()
    OverlapIntersect()
    Move(-45, 0)
    SetWidth(${width_latin})

    Select(0u2588); Copy() # Full block
    Select(65552);  Paste() # Temporary glyph
    Move(0, 600)
    PasteWithOffset(0, -1025)
    if (input_list[i] == "${input_latin_regular}")
        PasteWithOffset(248, 0)
    else
        PasteWithOffset(209, 0)
    endif
    RemoveOverlap()
    Copy()
    Select("ldot.a")
    PasteInto()
    OverlapIntersect()
    SetWidth(${width_latin})

    Select(65552); Clear() # Temporary glyph

    Select("l.a"); Copy();           Select("l"); Paste(); SetWidth(${width_latin})
    Select("lacute.a"); Copy();      Select("lacute"); Paste(); SetWidth(${width_latin})
    Select("lcaron.a"); Copy();      Select("lcaron"); Paste(); SetWidth(${width_latin})
    Select("uni013C.a"); Copy();     Select("uni013C"); Paste(); SetWidth(${width_latin})
    Select("uni1E37.a"); Copy();     Select("uni1E37"); Paste(); SetWidth(${width_latin})
    Select("uni1E39.a"); Copy();     Select("uni1E39"); Paste(); SetWidth(${width_latin})
    Select("uni1E3B.a"); Copy();     Select("uni1E3B"); Paste(); SetWidth(${width_latin})
    Select("lslash.a"); Copy();      Select("lslash"); Paste(); SetWidth(${width_latin})
    Select("ldot.a"); Copy();        Select("ldot"); Paste(); SetWidth(${width_latin})
    Select("uni026B.a"); Copy();     Select("uni026B"); Paste(); SetWidth(${width_latin})
    Select("uni026C.a"); Copy();     Select("uni026C"); Paste(); SetWidth(${width_latin})

# φ (.a のグリフに置換)
    Select("phi.a"); Copy();         Select("phi"); Paste(); SetWidth(${width_latin})

# Ŋ (.a のグリフに置換)
    Select("uni014A.a"); Copy();     Select("uni014A"); Paste(); SetWidth(${width_latin})

# D (ss 用、クロスバーを付加することで少しくどい感じに)
    Select(0u0044); Copy() # D
    Select(${address_store_mod}); Paste() # 保管所
    Select(${address_store_mod} + ${num_mod_glyphs}); Paste()
    Select(${address_store_mod} + ${num_mod_glyphs} * 2); Paste()
    Select(${address_store_mod} + ${num_mod_glyphs} * 3); Paste()
    Select(${address_store_mod} + ${num_mod_glyphs} * 4); Paste()
    Select(${address_store_mod} + ${num_mod_glyphs} * 5); Paste()

    Select(0u00af); Copy()  # macron
    Select(65552);  Paste() # Temporary glyph
    if (input_list[i] == "${input_latin_regular}")
        Scale(75, 110); Copy()
        Select(0u0044) # D
        PasteWithOffset(-175, -308)
    else
        Scale(80, 110); Copy()
        Select(0u0044) # D
        PasteWithOffset(-160, -331)
    endif
    SetWidth(${width_latin})
    RemoveOverlap()
    Select(65552);  Clear() # Temporary glyph

# J (リーゼントを少しカット)
    Select(0u2588); Copy() # Full block
    Select(65552);  Paste() # Temporary glyph
    if (input_list[i] == "${input_latin_regular}")
        Move(138 + 60, 0)
    else
        Move(117 + 60, 0)
    endif
    PasteWithOffset(0, -500)
    PasteWithOffset(0, 1090)
    RemoveOverlap()
    Copy()
    Select(0u004a) # J
    SelectMore(0u0134) # Ĵ
 #    SelectMore(0u0248) # Ɉ
 #    SelectMore(0ua7b2) # Ʝ
    PasteInto()
    OverlapIntersect()
    SetWidth(${width_latin})
    # キリル文字
    Select(0u004a); Copy() # J
    Select(0u0408); Paste() # Ј
    SetWidth(${width_latin})
    Select(65552); Clear() # Temporary glyph

# Q (ss用、突き抜けた尻尾でOと区別しやすく)
    Select(0u0051); Copy() # Q
    Select(${address_store_mod} + 1); Paste() # 保管所
    Select(${address_store_mod} + ${num_mod_glyphs} + 1); Paste()
    Select(${address_store_mod} + ${num_mod_glyphs} * 2 + 1); Paste()
    Select(${address_store_mod} + ${num_mod_glyphs} * 3 + 1); Paste()
    Select(${address_store_mod} + ${num_mod_glyphs} * 4 + 1); Paste()
    Select(${address_store_mod} + ${num_mod_glyphs} * 5 + 1); Paste()

    Select(0u002d); Copy() # Hyphen-minus
    Select(65552);  Paste() # Temporary glyph
    if (input_list[i] == "${input_latin_regular}")
        Scale(18, 250)
        Copy()
        Select(0u0051); PasteWithOffset(0, -205) # Q
    else
        Scale(24, 180)
        Copy()
        Select(0u0051); PasteWithOffset(0, -160) # Q
    endif

    SetWidth(${width_latin})
    RemoveOverlap()
    Select(65552); Clear() # Temporary glyph

# V (ss用、左上にセリフを追加してYやレと区別しやすく)
    Select(0u0056); Copy() # V
    Select(${address_store_mod} + 2); Paste() # 保管所
    Select(${address_store_mod} + ${num_mod_glyphs} + 2); Paste()
    Select(${address_store_mod} + ${num_mod_glyphs} * 2 + 2); Paste()
    Select(${address_store_mod} + ${num_mod_glyphs} * 3 + 2); Paste()
    Select(${address_store_mod} + ${num_mod_glyphs} * 4 + 2); Paste()
    Select(${address_store_mod} + ${num_mod_glyphs} * 5 + 2); Paste()

    # セリフ追加
    Select(0u00af); Copy() # macron
    Select(65552);  Paste() # Temporary glyph
    if (input_list[i] == "${input_latin_regular}")
        Scale(75, 110); Copy()
        Select(0u0056); # V
        PasteWithOffset(-205, -5) # V
    else
        Scale(80, 110); Copy()
        Select(0u0056); # V
        PasteWithOffset(-190, -38) # V
    endif

    SetWidth(${width_latin})
    RemoveOverlap()
    Select(65552); Clear() # Temporary glyph

# Z (ss用、クロスバーを付加してゼェーットな感じに)
    Select(0u005a); Copy() # Z
    Select(${address_store_mod} + 3); Paste() # 保管所
    Select(${address_store_mod} + ${num_mod_glyphs} + 3); Paste()
    Select(${address_store_mod} + ${num_mod_glyphs} * 2 + 3); Paste()
    Select(${address_store_mod} + ${num_mod_glyphs} * 3 + 3); Paste()
    Select(${address_store_mod} + ${num_mod_glyphs} * 4 + 3); Paste()
    Select(${address_store_mod} + ${num_mod_glyphs} * 5 + 3); Paste()

    Select(0u00af); Copy()  # macron
    Select(65552);  Paste() # Temporary glyph
    Scale(100, 110); Rotate(-2)
    Copy()
    Select(0u005a) # Z
    if (input_list[i] == "${input_latin_regular}")
        PasteWithOffset(0, -307)
    else
        PasteWithOffset(-1, -319)
    endif
    SetWidth(${width_latin})
    RemoveOverlap()
    Select(65552);  Clear() # Temporary glyph

# i (左端を少しカットして左に移動)
    Select(0u2588); Copy() # Full block
    Select(65552);  Paste() # Temporary glyph
    Move(0, 920)
    PasteWithOffset(0, -635)
    if (input_list[i] == "${input_latin_regular}")
        PasteWithOffset(92 + 15, 0)
    else
        PasteWithOffset(81 + 15, 0)
    endif
    RemoveOverlap()
    Copy()
    # ラテン文字
    Select(0u0069) # i
    SelectMore(0u00ec) # ì
    SelectMore(0u00ed) # í
    SelectMore(0u00ee) # î
    SelectMore(0u00ef) # ï
    SelectMore(0u0129) # ĩ
    SelectMore(0u012b) # ī
    SelectMore(0u012d) # ĭ
    SelectMore(0u012f) # į
    SelectMore(0u0131) # ı
    SelectMore(0u01d0) # ǐ
    SelectMore(0u0268) # ɨ
    SelectMore(0u1ec9) # ỉ
    SelectMore(0u1ecb) # ị
 #    SelectMore(0u0209) # ȉ
 #    SelectMore(0u020b) # ȋ
 #    SelectMore(0u1d96) # ᶖ
 #    SelectMore(0u1e2d) # ḭ
 #    SelectMore(0u1e2f) # ḯ
    # キリル文字
    SelectMore(0u0456) # і
    SelectMore(0u0457) # ї
    PasteInto()
    OverlapIntersect()
    Move(-20, 0)
    SetWidth(${width_latin})

# j (右に少し移動)
    # ラテン文字
    Select(0u006a) # j
    SelectMore(0u0135) # ĵ
 #    SelectMore(0u01f0) # ǰ
    SelectMore(0u0237) # ȷ
 #    SelectMore(0u0249) # ɉ
    SelectMore(0u029d) # ʝ
    # ギリシア文字
 #    SelectMore(0u03f3) # ϳ
    # キリル文字
    SelectMore(0u0458) # ј
    Move(20, 0)
    SetWidth(${width_latin})

# r (右に少し移動)
    Select(0u0072) # r
    SelectMore(0u0155) # ŕ
    SelectMore(0u0157) # ŗ
    SelectMore(0u0159) # ř
    SelectMore(0u027d, 0u027e) # ɽɾ
    SelectMore(0u1e5b) # ṛ
    SelectMore(0u1e5d) # ṝ
    SelectMore(0u1e5f) # ṟ
 #    SelectMore(0u0211) # ȑ
 #    SelectMore(0u0213) # ȓ
 #    SelectMore(0u024d) # ɍ
 #    SelectMore(0u027c) # ɼ
 #    SelectMore(0u1d72, 0u1d73) # ᵲᵳ
 #    SelectMore(0u1d89) # ᶉ
 #    SelectMore(0ua75b) # ꝛ
 #    SelectMore(0ua7a7) # ꞧ
 #    SelectMore(0uab47) # ꭇ
 #    SelectMore(0uab49) # ꭉ
    Move(10, 0)
    SetWidth(${width_latin})

# Ǝ (ベースフォントを置き換え)
    Select(0u0045); Copy() # E
    Select(0u018e); Paste() # Ǝ
    HFlip()
    CorrectDirection()
    SetWidth(${width_latin})

# 記号のグリフを加工
    Print("Edit symbols")

# * (上げる)
    Select(0u002a) # *
    Move(0, 10)
    SetWidth(${width_latin})

# $ (縦線を接続)
 #    Select(0u007c); Copy() # |
 #    Select(65552);  Paste() # Temporary glyph
 #    if (input_list[i] == "${input_latin_regular}")
 #        Scale(81, 86)
 #        Copy()
 #        Select(0u0024); PasteWithOffset(7, 70) # $
 #    else
 #        Scale(76, 86)
 #        Copy()
 #        Select(0u0024); PasteWithOffset(4, 69) # $
 #    endif
 #    RemoveOverlap()
 #    SetWidth(${width_latin})
 #    Select(65552);  Clear() # Temporary glyph

# % (斜め線を接続)
    # / を削除
    Select(0u2588); Copy() # Full block
    Select(65552);  Paste() # Temporary glyph
    if (input_list[i] == "${input_latin_regular}")
        Move(-265, 695)
        PasteWithOffset(265, -645)
    else
        Move(-265, 695)
        PasteWithOffset(265, -645)
    endif
    RemoveOverlap()
    Copy()
    Select(0u0025); PasteInto() # %
    OverlapIntersect()
    # / を追加
    Select(0u007c); Copy() # |
    Select(65552);  Paste() # Temporary glyph
    if (input_list[i] == "${input_latin_regular}")
        Scale(75, 75)
    else
        Scale(55, 75)
    endif
    Rotate(-43)
    Move(0, 70)
    Copy()
    Select(0u0025); PasteInto() # %
    SetWidth(${width_latin})
    Select(65552);  Clear() # Temporary glyph

# _ (上げる)
    Select(0u005f) # _
    Move(0, ${move_y_latin_underbar})
    SetWidth(${width_latin})

# ‶ (ベースフォントを置き換え)
    Select(0u2033); Copy() # ″
    Select(0u2036); Paste() # ‶
    HFlip()
    CorrectDirection()
    SetWidth(${width_latin})

# \`´′″‵‶ (拡大する ※‶ の加工の後に処理すること)
    Select(0u0060) # \`
    SelectMore(0u00b4) # ´
    SelectMore(0u2032, 0u2033) # ′″
    SelectMore(0u2035, 0u2036) # ‵‶
    Scale(120, 120,  ${width_latin} / 2, 690)
    SetWidth(${width_latin})

# ‟ (ベースフォントを置き換え)
    Select(0u201d); Copy() # ”
    Select(0u201f); Paste() # ‟
    HFlip()
    CorrectDirection()
    SetWidth(${width_latin})

# ℅ (斜め線を接続)
    # / を削除
    Select(0u2588); Copy() # Full block
    Select(65552);  Paste() # Temporary glyph
    if (input_list[i] == "${input_latin_regular}")
        Move(-265, 695)
        PasteWithOffset(265, -645)
    else
        Move(-265, 695)
        PasteWithOffset(265, -645)
    endif
    RemoveOverlap()
    Copy()
    Select(0u2105); PasteInto() # ℅
    OverlapIntersect()
    # / を追加
    Select(0u007c); Copy() # |
    Select(65552);  Paste() # Temporary glyph
    if (input_list[i] == "${input_latin_regular}")
        Scale(75, 75)
    else
        Scale(55, 75)
    endif
    Rotate(-43)
    Move(0, 70)
    Copy()
    Select(0u2105); PasteInto() # ℅
    SetWidth(${width_latin})
    Select(65552);  Clear() # Temporary glyph

# ℧ (ベースフォントを置き換え)
    Select(0u2126); Copy() # Ω
    Select(0u2127); Paste() # ℧
    Rotate(180)
    SetWidth(${width_latin})

# K (ベースフォントを置き換え)
    Select(0u004b); Copy() # K
    Select(0u212a); Paste() # K
    SetWidth(${width_latin})

# Å (ベースフォントを置き換え)
    Select(0u00c5); Copy() # Å
    Select(0u212b); Paste() # Å
    SetWidth(${width_latin})

# ⅋ (ベースフォントを置き換え)
    Select(0u0026); Copy() # &
    Select(0u214b); Paste() # ⅋
    Rotate(180)
    SetWidth(${width_latin})

# ∇ (ベースフォントを置き換え)
    Select(0u2206); Copy() # ∆
    Select(0u2207); Paste() # ∇
    VFlip()
    CorrectDirection()
    SetWidth(${width_latin})

# ∐ (ベースフォントを置き換え)
    Select(0u220f); Copy() # ∏
    Select(0u2210); Paste() # ∐
    VFlip()
    CorrectDirection()
    SetWidth(${width_latin})

# ∗ (ベースフォントを置き換え)
    Select(0u002a) # *
    Copy()
    Select(0u2217) # ∗
    Paste()
    SetWidth(${width_latin})

# スラッシュ無し0を作成
    Print("Edit slashed zero")

    # 通常 (上付き、下付きは後で加工)
    Select(0u0030); Copy() # 0
    Select(${address_store_zero}); Paste() # 保管所
    Select(0u004f); Copy() # O
    Select(65552);  Paste() # Temporary glyph
    if (input_list[i] == "${input_latin_regular}")
        Scale(88, 100)
    endif
    ChangeWeight(30)
    Copy()
    Select(${address_store_zero}); PasteInto() # 保管所
    OverlapIntersect()
    SetWidth(${width_latin})
    Copy()
    Select(${address_store_zero} + 3); Paste() # 下線無し全角
    Select(${address_store_zero} + 4); Paste() # 下線付き全角横書き
    Select(${address_store_zero} + 5); Paste() # 下線付き全角縦書き

    Select(65552); Clear() # Temporary glyph

# 0 (.a のグリフに置換して反転)
    Select("zero.a"); Copy(); Select("zero"); Paste()
    HFlip()
    CorrectDirection()
    SetWidth(${width_latin})

# ⁄ (Slash と区別するため分割、角度変更)
    Select(0u007c); Copy() # |
    Select(65552);  Paste() # Temporary glyph
    if (input_list[i] == "${input_latin_regular}")
        Scale(75, 75)
    else
        Scale(55, 75)
    endif
    Rotate(-43)
    Move(0, 70)
    Copy()
    Select(0u2044); Paste() # ⁄ Fraction slash
    Select(${address_store_visi_latin}); Paste() # 保管所
    SetWidth(${width_latin})

    Select(0u2044); Copy() # ⁄
    Select(65552);  Paste() # Temporary glyph
    Scale(120); Copy()
    Select(0u2044) # ⁄
    PasteWithOffset(335, 355); PasteWithOffset(-335, -355)
    OverlapIntersect()
    SetWidth(${width_latin})

    Select(65552); Clear() # Temporary glyph

# ∕ (Slash と区別するため角度変更)
    Select(0u007c); Copy() # |
    Select(65552);  Paste() # Temporary glyph
    if (input_list[i] == "${input_latin_regular}")
        Scale(75, 75)
    else
        Scale(55, 75)
    endif
    Rotate(-43)
    Move(0, 70)
    Copy()
    Select(0u2215); Paste() # ∕ Division slash
    SetWidth(${width_latin})

    Select(65552); Clear() # Temporary glyph

# | (破線にし、縦を短くする)
# ¦ (隙間を開ける)

    # 破線無しを保管して加工
    Select(0u007c); Move(0, 26) # |
    Copy() # |
    Select(${address_store_visi_latin} + 1); Paste() # 保管所
    Move(0, 75)
    PasteWithOffset(0, -75)
    OverlapIntersect()
    SetWidth(${width_latin})

    # ¦
    Select(0u007c); Copy() # |
    Select(0u00a6); Paste() # ¦
    Move(0, 625)
    PasteWithOffset(0, -625)

    # |
    Select(0u007c) # |
    Move(0, 535)
    PasteWithOffset(0, -535)

    # 保管したグリフを利用して高さを統一
    Select(${address_store_visi_latin} + 1); Copy() # 保管所
    Select(0u007c); PasteInto() # |
    OverlapIntersect()
    SetWidth(${width_latin})

    Select(0u00a6); PasteInto() # ¦
    OverlapIntersect()
    SetWidth(${width_latin})

    # リガチャ対応
    if ("${liga_flag}" == "true")
        # 破線無しを保管して加工
        Select(0ue104); Move(0, 26) # ||
        Copy() # |
        Select(${address_store_liga}); Paste() # 保管所
        Move(0, 75)
        PasteWithOffset(0, -75)
        OverlapIntersect()
        SetWidth(${width_latin})

        # ||
        Select(0ue104); Copy() # ||
        Move(0, 535)
        PasteWithOffset(0, -535)

        # 保管したグリフを利用して高さを統一
        Select(${address_store_liga}); Copy() # 保管所
        Select(0ue104); PasteInto() # ||
        OverlapIntersect()
        SetWidth(${width_latin})
    endif

# 上付き、下付き文字を追加、sups、subs フィーチャを追加
    Print("Edit superscrips and subscripts")

    # 下付き
    lookups = GetLookups("GSUB"); numlookups = SizeOf(lookups)
    lookupName = "'subs' 下つき文字"
    AddLookup(lookupName, "gsub_single", 0, [["subs",[["DFLT",["dflt"]]]]])
    lookupSub = lookupName + "サブテーブル"
    AddLookupSubtable(lookupName, lookupSub)

    orig = [0u002b, 0u002d, 0u003d, 0u0028, 0u0029] # +-=()
    subs = [0u208a, 0u208b, 0u208c, 0u208d, 0u208e] # ₊₋₌₍₎ # グリフ作成
    j = 0
    while (j < SizeOf(orig))
        Select(orig[j]); Copy()
        Select(subs[j]); Paste()
        Scale(${scale_width_super_sub}, ${scale_height_super_sub}, ${width_latin} / 2, 0)
        ChangeWeight(${weight_super_sub})
        CorrectDirection()
        Move(0, ${move_y_sub})
        Scale(${scale_super_sub2}, ${width_latin} / 2, ${move_y_sub} + ${center_height_super_sub})
        SetWidth(${width_latin})
        glyphName = GlyphInfo("Name") # subs フィーチャ追加
        Select(orig[j])
        AddPosSub(lookupSub, glyphName)
        j += 1
    endloop

    orig = [0u0061, 0u0065, 0u0068, 0u0069,\
            0u006a, 0u006b, 0u006c, 0u006d,\
            0u006e, 0u006f, 0u0070, 0u0072,\
            0u0073, 0u0074, 0u0075, 0u0076,\
            0u0078] # aehi jklm nopr stuv x
    subs = [0u2090, 0u2091, 0u2095, 0u1d62,\
            0u2c7c, 0u2096, 0u2097, 0u2098,\
            0u2099, 0u2092, 0u209a, 0u1d63,\
            0u209b, 0u209c, 0u1d64, 0u1d65,\
            0u2093] # ₐₑₕᵢ ⱼₖₗₘ ₙₒₚᵣ ₛₜᵤᵥ ₓ # グリフ作成
    j = 0
    while (j < SizeOf(orig))
        Select(orig[j]); Copy()
        Select(subs[j]); Paste()
        Scale(${scale_width_super_sub}, ${scale_height_super_sub}, ${width_latin} / 2, 0)
        ChangeWeight(${weight_super_sub})
        CorrectDirection()
        Move(0, ${move_y_sub})
        Scale(${scale_super_sub2}, ${width_latin} / 2, ${move_y_sub} + ${center_height_super_sub})
        SetWidth(${width_latin})
        glyphName = GlyphInfo("Name") # subs フィーチャ追加
        Select(orig[j])
        AddPosSub(lookupSub, glyphName)
        j += 1
    endloop

    orig = [0u03b2, 0u03b3, 0u03c1, 0u03c6, 0u03c7, 0u0259] # βγρφχə
    subs = [0u1d66, 0u1d67, 0u1d68, 0u1d69, 0u1d6a, 0u2094] # ᵦᵧᵨᵩᵪₔ # グリフ作成
    j = 0
    while (j < SizeOf(orig))
        Select(orig[j]); Copy()
        Select(subs[j]); Paste()
        Scale(${scale_width_super_sub}, ${scale_height_super_sub}, ${width_latin} / 2, 0)
        ChangeWeight(${weight_super_sub})
        CorrectDirection()
        Move(0, ${move_y_sub})
        Scale(${scale_super_sub2}, ${width_latin} / 2, ${move_y_sub} + ${center_height_super_sub})
        SetWidth(${width_latin})
        glyphName = GlyphInfo("Name") # subs フィーチャ追加
        Select(orig[j])
        AddPosSub(lookupSub, glyphName)
        j += 1
    endloop

    orig = [0u0030, 0u0031, 0u0032, 0u0033,\
            0u0034, 0u0035, 0u0036, 0u0037,\
            0u0038, 0u0039] # 0-9
    subs = [0u2080, 0u2081, 0u2082, 0u2083,\
            0u2084, 0u2085, 0u2086, 0u2087,\
            0u2088, 0u2089] # ₀-₉ # グリフ置き換え
    j = 0
    while (j < SizeOf(orig))
        Select(orig[j]); Copy()
        Select(subs[j]); Paste()
        Scale(${scale_width_super_sub}, ${scale_height_super_sub}, ${width_latin} / 2, 0)
        ChangeWeight(${weight_super_sub})
        CorrectDirection()
        Move(0, ${move_y_sub})
        Scale(${scale_super_sub2}, ${width_latin} / 2, ${move_y_sub} + ${center_height_super_sub})
        SetWidth(${width_latin})
        glyphName = GlyphInfo("Name") # subs フィーチャ追加
        Select(orig[j])
        AddPosSub(lookupSub, glyphName)
        j += 1
    endloop

    # 保管した下付きスラッシュ無し0
    Select(${address_store_zero}); Copy() # 保管所 (通常の0)
    Select(${address_store_zero} + 2); Paste() # 保管所
    Scale(${scale_width_super_sub}, ${scale_height_super_sub}, ${width_latin} / 2, 0)
    ChangeWeight(${weight_super_sub})
    CorrectDirection()
    Move(0, ${move_y_sub})
    Scale(${scale_super_sub2}, ${width_latin} / 2, ${move_y_sub} + ${center_height_super_sub})
    SetWidth(${width_latin})

    # 上付き
    lookups = GetLookups("GSUB"); numlookups = SizeOf(lookups)
    lookupName = "'sups' 上つき文字"
    AddLookup(lookupName, "gsub_single", 0, [["sups",[["DFLT",["dflt"]]]]])
    lookupSub = lookupName + "サブテーブル"
    AddLookupSubtable(lookupName, lookupSub)

    orig = [0u002b, 0u002d, 0u003d, 0u0028, 0u0029] # +-=()
    sups = [0u207a, 0u207b, 0u207c, 0u207d, 0u207e] # ⁺⁻⁼⁽⁾ # グリフ作成
    j = 0
    while (j < SizeOf(orig))
        Select(orig[j]); Copy()
        Select(sups[j]); Paste()
        Scale(${scale_width_super_sub}, ${scale_height_super_sub}, ${width_latin} / 2, 0)
        ChangeWeight(${weight_super_sub})
        CorrectDirection()
        Move(0, ${move_y_super})
        Scale(${scale_super_sub2}, ${width_latin} / 2, ${move_y_super} + ${center_height_super_sub})
        SetWidth(${width_latin})
        glyphName = GlyphInfo("Name") # sups フィーチャ追加
        Select(orig[j])
        AddPosSub(lookupSub, glyphName)
        j += 1
    endloop

    orig = [0u0061, 0u0065, 0u0068, 0u0069,\
            0u006a, 0u006b, 0u006c, 0u006d,\
            0u006e, 0u006f, 0u0070, 0u0072,\
            0u0073, 0u0074, 0u0075, 0u0076,\
            0u0078] # aehi jklm nopr stuv x
    sups = [0u1d43, 0u1d49, 0u02b0, 0u2071,\
            0u02b2, 0u1d4f, 0u02e1, 0u1d50,\
            0u207f, 0u1d52, 0u1d56, 0u02b3,\
            0u02e2, 0u1d57, 0u1d58, 0u1d5b,\
            0u02e3] # ᵃᵉʰⁱ ʲᵏˡᵐ ⁿᵒᵖʳ ˢᵗᵘᵛ ˣ # グリフ作成
    j = 0
    while (j < SizeOf(orig))
        Select(orig[j]); Copy()
        Select(sups[j]); Paste()
        Scale(${scale_width_super_sub}, ${scale_height_super_sub}, ${width_latin} / 2, 0)
        ChangeWeight(${weight_super_sub})
        CorrectDirection()
        Move(0, ${move_y_super})
        Scale(${scale_super_sub2}, ${width_latin} / 2, ${move_y_super} + ${center_height_super_sub})
        SetWidth(${width_latin})
        glyphName = GlyphInfo("Name") # sups フィーチャ追加
        Select(orig[j])
        AddPosSub(lookupSub, glyphName)
        j += 1
    endloop

    orig = [0u0062, 0u0063, 0u0064, 0u0066,\
            0u0067, 0u0077, 0u0079, 0u007a] # bcdf gwyz
    sups = [0u1d47, 0u1d9c, 0u1d48, 0u1da0,\
            0u1d4d, 0u02b7, 0u02b8, 0u1dbb] # ᵇᶜᵈᶠ ᵍʷʸᶻ # グリフ作成
    j = 0
    while (j < SizeOf(orig))
        Select(orig[j]); Copy()
        Select(sups[j]); Paste()
        Scale(${scale_width_super_sub}, ${scale_height_super_sub}, ${width_latin} / 2, 0)
        ChangeWeight(${weight_super_sub})
        CorrectDirection()
        Move(0, ${move_y_super})
        Scale(${scale_super_sub2}, ${width_latin} / 2, ${move_y_super} + ${center_height_super_sub})
        SetWidth(${width_latin})
        glyphName = GlyphInfo("Name") # sups フィーチャ追加
        Select(orig[j])
        AddPosSub(lookupSub, glyphName)
        j += 1
    endloop

    orig = [0u0041, 0u0042, 0u0044, 0u0045,\
            0u0047, 0u0048, 0u0049, 0u004a,\
            0u004b, 0u004c, 0u004d, 0u004e,\
            0u004f, 0u0050, 0u0052, 0u0054,\
            0u0055, 0u0056, 0u0057] # ABDE GHIJ KLMN OPRT UVW
    sups = [0u1d2c, 0u1d2e, 0u1d30, 0u1d31,\
            0u1d33, 0u1d34, 0u1d35, 0u1d36,\
            0u1d37, 0u1d38, 0u1d39, 0u1d3a,\
            0u1d3c, 0u1d3e, 0u1d3f, 0u1d40,\
            0u1d41, 0u2c7d, 0u1d42] # ᴬᴮᴰᴱ ᴳᴴᴵᴶ ᴷᴸᴹᴺ ᴼᴾᴿᵀ ᵁⱽᵂ # グリフ作成
    j = 0
    while (j < SizeOf(orig))
        if (orig[j] == 0u0044) # D
            Select(${address_store_mod}); Copy() # 保管した D
        elseif  (orig[j] == 0u0056) # V
            Select(${address_store_mod} + 2); Copy() # 保管した V
        else
            Select(orig[j]); Copy()
        endif
        Select(sups[j]); Paste()
        Scale(${scale_width_super_sub}, ${scale_height_super_sub}, ${width_latin} / 2, 0)
        ChangeWeight(${weight_super_sub})
        CorrectDirection()
        Move(0, ${move_y_super})
        Scale(${scale_super_sub2}, ${width_latin} / 2, ${move_y_super} + ${center_height_super_sub})
        SetWidth(${width_latin})
        glyphName = GlyphInfo("Name") # sups フィーチャ追加
        Select(orig[j])
        AddPosSub(lookupSub, glyphName)
        j += 1
    endloop

    orig = [0u03b2, 0u03b3, 0u03b4, 0u03c6, 0u03c7, 0u0259] # βγδφχə
    sups = [0u1d5d, 0u1d5e, 0u1d5f, 0u1d60, 0u1d61, 0u1d4a] # ᵝᵞᵟᵠᵡᵊ # グリフ作成
    j = 0
    while (j < SizeOf(orig))
        Select(orig[j]); Copy()
        Select(sups[j]); Paste()
        Scale(${scale_width_super_sub}, ${scale_height_super_sub}, ${width_latin} / 2, 0)
        ChangeWeight(${weight_super_sub})
        CorrectDirection()
        Move(0, ${move_y_super})
        Scale(${scale_super_sub2}, ${width_latin} / 2, ${move_y_super} + ${center_height_super_sub})
        SetWidth(${width_latin})
        glyphName = GlyphInfo("Name") # sups フィーチャ追加
        Select(orig[j])
        AddPosSub(lookupSub, glyphName)
        j += 1
    endloop

    orig = [0u00c6, 0u00f0, 0u018e, 0u014b,\
            0u03b8] # ÆðƎŋ θ
    sups = [0u1d2d, 0u1d9e, 0u1d32, 0u1d51,\
            0u1dbf] # ᴭᶞᴲᵑ ᶿ # グリフ作成
    j = 0
    while (j < SizeOf(orig))
        Select(orig[j]); Copy()
        Select(sups[j]); Paste()
        Scale(${scale_width_super_sub}, ${scale_height_super_sub}, ${width_latin} / 2, 0)
        ChangeWeight(${weight_super_sub})
        CorrectDirection()
        Move(0, ${move_y_super})
        Scale(${scale_super_sub2}, ${width_latin} / 2, ${move_y_super} + ${center_height_super_sub})
        SetWidth(${width_latin})
        glyphName = GlyphInfo("Name") # sups フィーチャ追加
        Select(orig[j])
        AddPosSub(lookupSub, glyphName)
        j += 1
    endloop

    orig = [0u043d] # н
    sups = [0u1d78] # ᵸ # グリフ作成
    j = 0
    while (j < SizeOf(orig))
        Select(orig[j]); Copy()
        Select(sups[j]); Paste()
        Scale(${scale_width_super_sub}, ${scale_height_super_sub}, ${width_latin} / 2, 0)
        ChangeWeight(${weight_super_sub})
        CorrectDirection()
        Move(0, ${move_y_super})
        Scale(${scale_super_sub2}, ${width_latin} / 2, ${move_y_super} + ${center_height_super_sub})
        SetWidth(${width_latin})
        glyphName = GlyphInfo("Name") # sups フィーチャ追加
        Select(orig[j])
        AddPosSub(lookupSub, glyphName)
        j += 1
    endloop

    orig = [0u0250, 0u0251, 0u0252, 0u0254,\
            0u0255, 0u025b, 0u025c, 0u025f,\
            0u0261, 0u0265, 0u0268,\
            0u026a, 0u026d, 0u026f, 0u0270,\
            0u0271, 0u0272, 0u0273, 0u0274,\
            0u0275, 0u0278, 0u0282, 0u0283,\
            0u0289, 0u028a, 0u028b, 0u028c,\
            0u0290, 0u0291, 0u0292, 0u029d,\
            0u029f, 0u0266, 0u0279, 0u027b,\
            0u0281, 0u0294, 0u0295, 0u0263]
            # ɐɑɒɔ ɕɛɜɟ ɡɥɨ ɪɭɯɰ ɱɲɳɴ ɵɸʂʃ ʉʊʋʌ ʐʑʒʝ ʟɦɹɻ ʁʔʕɣ
    sups = [0u1d44, 0u1d45, 0u1d9b, 0u1d53,\
            0u1d9d, 0u1d4b, 0u1d9f, 0u1da1,\
            0u1da2, 0u1da3, 0u1da4,\
            0u1da6, 0u1da9, 0u1d5a, 0u1dad,\
            0u1dac, 0u1dae, 0u1daf, 0u1db0,\
            0u1db1, 0u1db2, 0u1db3, 0u1db4,\
            0u1db6, 0u1db7, 0u1db9, 0u1dba,\
            0u1dbc, 0u1dbd, 0u1dbe, 0u1da8,\
            0u1dab, 0u02b1, 0u02b4, 0u02b5,\
            0u02b6, 0u02c0, 0u02c1, 0u02e0]
            # ᵄᵅᶛᵓ ᶝᵋᶟᶡ ᶢᶣᶤ ᶦᶩᵚᶭ ᶬᶮᶯᶰ ᶱᶲᶳᶴ ᶶᶷᶹᶺ ᶼᶽᶾᶨ ᶫʱʴʵ ʶˀˁˠ # グリフ作成
 #    orig = [0u0250, 0u0251, 0u0252, 0u0254,\
 #            0u0255, 0u025b, 0u025c, 0u025f,\
 #            0u0261, 0u0265, 0u0268, 0u0269,\
 #            0u026a, 0u026d, 0u026f, 0u0270,\
 #            0u0271, 0u0272, 0u0273, 0u0274,\
 #            0u0275, 0u0278, 0u0282, 0u0283,\
 #            0u0289, 0u028a, 0u028b, 0u028c,\
 #            0u0290, 0u0291, 0u0292, 0u029d,\
 #            0u029f, 0u0266, 0u0279, 0u027b,\
 #            0u0281, 0u0294, 0u0295, 0u0263]
 #            # ɐɑɒɔ ɕɛɜɟ ɡɥɨɩ ɪɭɯɰ ɱɲɳɴ ɵɸʂʃ ʉʊʋʌ ʐʑʒʝ ʟɦɹɻ ʁʔʕɣ
 #    sups = [0u1d44, 0u1d45, 0u1d9b, 0u1d53,\
 #            0u1d9d, 0u1d4b, 0u1d9f, 0u1da1,\
 #            0u1da2, 0u1da3, 0u1da4, 0u1da5,\
 #            0u1da6, 0u1da9, 0u1d5a, 0u1dad,\
 #            0u1dac, 0u1dae, 0u1daf, 0u1db0,\
 #            0u1db1, 0u1db2, 0u1db3, 0u1db4,\
 #            0u1db6, 0u1db7, 0u1db9, 0u1dba,\
 #            0u1dbc, 0u1dbd, 0u1dbe, 0u1da8,\
 #            0u1dab, 0u02b1, 0u02b4, 0u02b5,\
 #            0u02b6, 0u02c0, 0u02c1, 0u02e0]
 #            # ᵄᵅᶛᵓ ᶝᵋᶟᶡ ᶢᶣᶤᶥ ᶦᶩᵚᶭ ᶬᶮᶯᶰ ᶱᶲᶳᶴ ᶶᶷᶹᶺ ᶼᶽᶾᶨ ᶫʱʴʵ ʶˀˁˠ # グリフ作成
    j = 0
    while (j < SizeOf(orig))
        Select(orig[j]); Copy()
        Select(sups[j]); Paste()
        Scale(${scale_width_super_sub}, ${scale_height_super_sub}, ${width_latin} / 2, 0)
        ChangeWeight(${weight_super_sub})
        CorrectDirection()
        Move(0, ${move_y_super})
        Scale(${scale_super_sub2}, ${width_latin} / 2, ${move_y_super} + ${center_height_super_sub})
        SetWidth(${width_latin})
        glyphName = GlyphInfo("Name") # sups フィーチャ追加
        Select(orig[j])
        AddPosSub(lookupSub, glyphName)
        j += 1
    endloop

 #    orig = [0u1d16, 0u1d17, 0u1d1d, 0u1d7b,\
 #            0u1d85, 0u01ab] # ᴖᴗᴝᵻ ᶅƫ
 #    sups = [0u1d54, 0u1d55, 0u1d59, 0u1da7,\
 #            0u1daa, 0u1db5] # ᵔᵕᵙᶧ ᶪᶵ # グリフ作成
 #    j = 0
 #    while (j < SizeOf(orig))
 #        Select(orig[j]); Copy()
 #        Select(sups[j]); Paste()
 #        Scale(${scale_width_super_sub}, ${scale_height_super_sub}, ${width_latin} / 2, 0)
 #        ChangeWeight(${weight_super_sub})
 #        CorrectDirection()
 #        Move(0, ${move_y_super})
 #        Scale(${scale_super_sub2}, ${width_latin} / 2, ${move_y_super} + ${center_height_super_sub})
 #        SetWidth(${width_latin})
 #        glyphName = GlyphInfo("Name") # sups フィーチャ追加
 #        Select(orig[j])
 #        AddPosSub(lookupSub, glyphName)
 #        j += 1
 #    endloop

    orig = [0u0030, 0u0031, 0u0032, 0u0033,\
            0u0034, 0u0035, 0u0036, 0u0037,\
            0u0038, 0u0039] # 0-9
    sups = [0u2070, 0u00b9, 0u00b2, 0u00b3,\
            0u2074, 0u2075, 0u2076, 0u2077,\
            0u2078, 0u2079] # ⁰-⁹ # グリフ置き換え
    j = 0
        while (j < SizeOf(orig))
        Select(orig[j]); Copy()
        Select(sups[j]); Paste()
        Scale(${scale_width_super_sub}, ${scale_height_super_sub}, ${width_latin} / 2, 0)
        ChangeWeight(${weight_super_sub})
        CorrectDirection()
        Move(0, ${move_y_super})
        Scale(${scale_super_sub2}, ${width_latin} / 2, ${move_y_super} + ${center_height_super_sub})
        SetWidth(${width_latin})
        glyphName = GlyphInfo("Name") # sups フィーチャ追加
        Select(orig[j])
        AddPosSub(lookupSub, glyphName)
        j += 1
    endloop

    # 保管した上付きスラッシュ無し0
    Select(${address_store_zero}); Copy() # 保管所 (通常の0)
    Select(${address_store_zero} + 1); Paste() # 保管所
    Scale(${scale_width_super_sub}, ${scale_height_super_sub}, ${width_latin} / 2, 0)
    ChangeWeight(${weight_super_sub})
    CorrectDirection()
    Move(0, ${move_y_super})
    Scale(${scale_super_sub2}, ${width_latin} / 2, ${move_y_super} + ${center_height_super_sub})
    SetWidth(${width_latin})

    sups = [0u02e4] # ˤ # 基本のグリフ無し、上付きのみ
 #    sups = [0u1d3b, 0u1d46, 0u1d4c, 0u1d4e, 0u02e4] # ᴻᵆᵌᵎˤ # 基本のグリフ無し、上付きのみ
    j = 0
    while (j < SizeOf(sups))
        Select(sups[j])
        Scale(${scale_super_sub2}, ${width_latin} / 2, ${move_y_super} + ${center_height_super_sub})
        ChangeWeight(${weight_super_sub})
        CorrectDirection()
        Move(0, ${move_y_super2})
        SetWidth(${width_latin})
        j += 1
    endloop

# 演算子を上下に移動
    math = [0u002a, 0u002b, 0u002d, 0u003c,\
            0u003d, 0u003e, 0u00d7, 0u00f7,\
            0u2212, 0u2217, 0u2260] # *+-< =>×÷ −∗≠
    j = 0
    while (j < SizeOf(math))
        Select(math[j]);
        Move(0, ${move_y_math})
        SetWidth(${width_latin})
        j += 1
    endloop

    math = [0u207a, 0u207b, 0u207c,\
            0u208a, 0u208b, 0u208c] # ⁺⁻⁼ ₊₋₌
    j = 0
    while (j < SizeOf(math))
        Select(math[j]);
        Move(0, ${move_y_s_math})
        SetWidth(${width_latin})
        j += 1
    endloop

# 括弧を上下に移動
    brkt = [0u0028, 0u0029, 0u005b, 0u005d,\
            0u007b, 0u007d] # ()[] {}
    j = 0
    while (j < SizeOf(brkt))
        Select(brkt[j]);
        Move(0, ${move_y_latin_bracket})
        SetWidth(${width_latin})
        j += 1
    endloop

# 一部の記号を全角にする
    Select(0u2190, 0u21ff) # ←-⇿
    SelectMore(0u2389, 0u238a) # ⎉⎊
    SelectMore(0u23fb, 0u23fe) # ⏻⏼⏽⏾
    SelectMore(0u2600, 0u2638) # ☀-☸
    SelectMore(0u263c, 0u26b1) # ☼-⚱
    SelectMore(0u2701, 0u27be) # ✁-➾
    SelectMore(0u27f0, 0u27ff) # ⟰-⟿
    SelectMore(0u2900, 0u297f) # ⤀-⥿
    SelectMore(0u2b00, 0u2bff) # ⬀-⯿

    SelectMore(0u1f3b5, 0u1f3b6) # 🎵🎶
    SelectMore(0u1f4a9)        # 💩
    SelectMore(0u1f512)        # 🔒
    SelectMore(0u1f916)        # 🤖
    foreach
        if (WorthOutputting())
            if (GlyphInfo("Width") <= 700)
                Move(${width_zenkaku} / 2 - ${width_latin} / 2, 0)
                Scale(${scale_hankaku2zenkaku}, ${width_zenkaku} / 2, ${center_height_hankaku})
                SetWidth(${width_zenkaku})
            endif
        endif
    endloop

# --------------------------------------------------

# Change the scale of hankaku glyphs
    if ("${draft_flag}" == "false")
        Print("Change the scale of hankaku glyphs")
        Select(0u0020, 0u1fff) # 基本ラテン - ギリシア文字拡張 # 一部全角
        SelectMore(0u2010, 0u218f) # 一般句読点 - 数字の形
        SelectMore(0u2200, 0u22ff) # 数学記号 # 全角半角混合
        SelectMore(0u27c0, 0u27ef) # その他の数学記号 A
        SelectMore(0u2980, 0u2aff) # その他の数学記号 B・補助数学記号
        SelectMore(0u2c60, 0u2c7f) # ラテン文字拡張 C
        SelectMore(0u2e00, 0u2e7f) # 補助句読点
        SelectMore(0ua700, 0ua7ff) # 声調装飾文字・ラテン文字拡張 D
        SelectMore(0ufb00, 0ufb4f) # アルファベット表示形
 #        SelectMore(0u1d538, 0u1d56b) # 数学用英数字記号
        if ("${liga_flag}" == "true")
            SelectMore(0ue100, 0ue129) # リガチャ
            SelectMore(${address_store_liga}, ${address_store_liga} + 1)
            SelectMore("LIG")
        endif
        foreach
            if (WorthOutputting())
                if (GlyphInfo("Width") <= 700)
                    Scale(${scale_width_latin}, ${scale_height_latin}, ${width_latin} / 2, 0)
                    Move(${move_x_hankaku_latin}, 0)
                    SetWidth(${width_hankaku})
                endif
            endif
        endloop

        Select(0u2190, 0u21ff) # 矢印
        SelectMore(0u2300, 0u231f) # その他の技術用記号 1 # 全角半角混合、縦横比固定
        SelectMore(0u2322, 0u239a) # その他の技術用記号 2
        SelectMore(0u23af) # その他の技術用記号 3
        SelectMore(0u23b4, 0u23bd) # その他の技術用記号 4
        SelectMore(0u23cd, 0u23ff) # その他の技術用記号 5
        SelectMore(0u2400, 0u24ff) # 制御機能用記号 - 囲み英数字
        SelectMore(0u25a0, 0u25ff) # 幾何学模様・その他の記号・装飾記号 # 全角半角混合、縦横比固定
        SelectMore(0u2600, 0u27bf) # その他の記号 - 装飾記号
        SelectMore(0u27f0, 0u27ff) # 補助矢印 A
        SelectMore(0u2900, 0u297f) # 補助矢印 B
        SelectMore(0u2b00, 0u2bff) # その他の記号および矢印 # 縦横比固定
        SelectMore(0ufffd) # � # 縦横比固定
        foreach
            if (WorthOutputting())
                if (GlyphInfo("Width") <= 700)
                    Scale(${scale_width_latin}, ${scale_width_latin}, ${width_latin} / 2, ${center_height_hankaku})
                    Move(${move_x_hankaku_latin}, 0)
    	              SetWidth(${width_hankaku})
                endif
            endif
        endloop

        Select(0u2320, 0u2321) # インテグラル # 高さそのまま
        SelectMore(0u239b, 0u23ae) # 括弧素片・インテグラル # 高さそのまま
        SelectMore(0u23b0, 0u23b3) # 括弧素片・総和記号部分
        foreach
            if (WorthOutputting())
                if (GlyphInfo("Width") <= 700)
                    Scale(${scale_width_latin}, 100, ${width_latin} / 2, ${center_height_hankaku})
                    Move(${move_x_hankaku_latin}, 0)
                    SetWidth(${width_hankaku})
                endif
            endif
        endloop

        Select(0u23be, 0u23cc) # 歯科表記記号
        SelectMore(0u2500, 0u259f) # 罫線素片・ブロック要素 # 高さそのまま、幅固定
        foreach
            if (WorthOutputting())
                if (GlyphInfo("Width") <= 700)
                    Scale(${scale_width_block}, 100, ${width_latin} / 2, ${center_height_hankaku})
                    Move(${move_x_hankaku_latin}, 0)
                    SetWidth(${width_hankaku})
                endif
            endif
        endloop

        Select(${address_store_mod}, ${address_store_mod} + ${num_mod_glyphs} * 6 - 1) # 保管したDQVZ
        SelectMore(${address_store_zero}, ${address_store_zero} + 5) # 保管したスラッシュ無し0
        SelectMore(${address_store_visi_latin}, ${address_store_visi_latin} + 1) # 保管した ⁄|
        Scale(${scale_width_latin}, ${scale_height_latin}, ${width_latin} / 2, 0)
        Move(${move_x_hankaku_latin}, 0)
        SetWidth(${width_hankaku})
    endif

# --------------------------------------------------

# 一部を除いた半角文字を拡大
    if (${scale_width_hankaku} != 100 || ${scale_height_hankaku} != 100)
        Print("Edit hankaku aspect ratio")

        Select(0u0020, 0u1fff) # 基本ラテン - ギリシャ文字拡張
        SelectMore(0u2010, 0u218f) # 一般句読点 - 数字の形
        SelectMore(0u2200, 0u22ff) # 数学記号
        SelectMore(0u27c0, 0u27ef) # その他の数学記号 A
        SelectMore(0u2980, 0u2aff) # その他の数学記号 B - 補助数学記号
        SelectMore(0u2c60, 0u2c7f) # ラテン文字拡張 C
        SelectMore(0u2e00, 0u2e7f) # 補助句読点
        SelectMore(0ua700, 0ua7ff) # 声調装飾文字 - ラテン文字拡張 D
        SelectMore(0ufb00, 0ufb4f) # アルファベット表示形
 #        SelectMore(0u1d538, 0u1d56b) # 数学用英数字記号
        if ("${liga_flag}" == "true")
            SelectMore(0ue100, 0ue129) # リガチャ
            SelectMore(${address_store_liga}, ${address_store_liga} + 1)
            SelectMore("LIG")
        endif
        foreach
            if (WorthOutputting())
                if (GlyphInfo("Width") <= 700)
                    Scale(${scale_width_hankaku}, ${scale_height_hankaku}, ${width_hankaku} / 2, 0)
                    SetWidth(${width_hankaku})
                endif
            endif
        endloop

        Select(0u2190, 0u21ff) # 矢印
        SelectMore(0u2300, 0u231f) # その他の技術用記号 1
        SelectMore(0u2322, 0u239a) # その他の技術用記号 2
        SelectMore(0u23af) # その他の技術用記号 3
        SelectMore(0u23b4, 0u23bd) # その他の技術用記号 4
        SelectMore(0u23cd, 0u23ff) # その他の技術用記号 5
        SelectMore(0u2400, 0u24ff) # 制御機能用記号 - 囲み英数字
        SelectMore(0u25a0, 0u25ff) # 幾何学模様
        SelectMore(0u2600, 0u27bf) # その他の記号 - 装飾記号
        SelectMore(0u27f0, 0u27ff) # 補助矢印 A
        SelectMore(0u2900, 0u297f) # 補助矢印 B
        SelectMore(0u2b00, 0u2bff) # その他の記号および矢印
        SelectMore(0ufffd) # 特殊用途文字
        foreach
            if (WorthOutputting())
                if (GlyphInfo("Width") <= 700)
                    Scale(${scale_width_hankaku}, ${scale_height_hankaku}, ${width_hankaku} / 2, ${center_height_hankaku})
                    SetWidth(${width_hankaku})
                endif
            endif
        endloop

        Select(0u2320, 0u2321) # インテグラル
        SelectMore(0u239b, 0u23ae) # 括弧素片・インテグラル
        SelectMore(0u23b0, 0u23b3) # 括弧素片・総和記号部分
        foreach
            if (WorthOutputting())
                if (GlyphInfo("Width") <= 700)
                    Scale(${scale_width_hankaku}, 100, ${width_hankaku} / 2, ${center_height_hankaku})
                    SetWidth(${width_hankaku})
                endif
            endif
        endloop

        Select(${address_store_mod}, ${address_store_mod} + ${num_mod_glyphs} * 6 - 1) # 保管したDQVZ
        SelectMore(${address_store_zero}, ${address_store_zero} + 5) # 保管したスラッシュ無し0
        SelectMore(${address_store_visi_latin}, ${address_store_visi_latin} + 1) # 保管した ⁄|
        Scale(${scale_width_hankaku}, ${scale_height_hankaku}, ${width_hankaku} / 2, 0)
        SetWidth(${width_hankaku})
    endif

# --------------------------------------------------

# 記号を一部クリア
    Print("Remove some glyphs")
    Select(0u0020); Clear() # 半角スペース
    Select(0u00a0); Clear() # ノーブレイクスペース
    Select(0u00bc, 0u00be); Clear() # ¼½¾
    Select(0u2013, 0u2015); Clear() # –—―
    Select(0u2025, 0u2026); Clear() # ‥…
    Select(0u2030, 0u2031); Clear() # ‰‱
    Select(0u2150, 0u215f); Clear() # ⅐-⅟
    Select(0u2189); Clear() # ↉
    Select(0u2190, 0u2199); Clear() # ←-↙
    Select(0u21a4, 0u21a8); Clear() # ↤-↨
    Select(0u21a9, 0u21aa); Clear() # ↩↪
    Select(0u21b0, 0u21b5); Clear() # ↰-↵
    Select(0u21b9); Clear() # ↹
    Select(0u21c4, 0u21ca); Clear() # ⇄-⇊
    Select(0u21d0, 0u21d9); Clear() # ⇐-⇙
    Select(0u21de, 0u21ed); Clear() # ⇞-⇭
    Select(0u21f5); Clear() # ⇵
    Select(0u221d, 0u221e); Clear() # ∝∞
    Select(0u221f); Clear() # ∟
    Select(0u2220); Clear() # ∠
    Select(0u2225); Clear() # ∥
    Select(0u2226); Clear() # ∦
    Select(0u222b, 0u222e); Clear() # ∫∬∭∮
    Select(0u223d); Clear() # ∽
    Select(0u22a2, 0u22a5); Clear() # ⊢⊣⊤⊥
    Select(0u22bf); Clear() # ⊿
    Select(0u22ee, 0u22ef); Clear() # ⋮⋯
    Select(0u2300); Clear() # ⌀
    Select(0u2302); Clear() # ⌂
    Select(0u2303); Clear() # ⌃
    Select(0u2312, 0u2313); Clear() # ⌒⌓
    Select(0u2316); Clear() # ⌖
    Select(0u2318); Clear() # ⌘
    Select(0u2324); Clear() # ⌤
    Select(0u2325); Clear() # ⌥
    Select(0u2326); Clear() # ⌦
    Select(0u2327); Clear() # ⌧
    Select(0u2328); Clear() # ⌨
    Select(0u232b); Clear() # ⌫
    Select(0u232d); Clear() # ⌭
    Select(0u232f); Clear() # ⌯
    Select(0u2330); Clear() # ⌰
    Select(0u2332); Clear() # ⌲
    Select(0u2333); Clear() # ⌳
    Select(0u2334); Clear() # ⌴
    Select(0u2335); Clear() # ⌵
    Select(0u2387); Clear() # ⎇
    Select(0u2388); Clear() # ⎈
    Select(0u238b); Clear() # ⎋
    Select(0u23ce); Clear() # ⏎
    Select(0u23cf); Clear() # ⏏
    Select(0u23e4); Clear() # ⏤
    Select(0u23e5); Clear() # ⏥
    Select(0u2425); Clear() # ␥
 #    Select(0u2500, 0u259f); Clear() # 罫線素片・ブロック要素
    Select(0u25a0, 0u25a1); Clear() # ■□
    Select(0u25ac, 0u25af); Clear() # ▬▭▮▯
    Select(0u25b0, 0u25b1); Clear() # ▰▱
    Select(0u25b2, 0u25b3); Clear() # ▲△
    Select(0u25b6, 0u25b7); Clear() # ▶▷
    Select(0u25ba, 0u25bd); Clear() # ►▻▼▽
    Select(0u25c0, 0u25c1); Clear() # ◀◁
    Select(0u25c4, 0u25c7); Clear() # ◄◅◆◇
    Select(0u25cb, 0u25cc); Clear() # ○◌
    Select(0u25ce, 0u25cf); Clear() # ◎●
    Select(0u25d9); Clear() # ◙
    Select(0u25e0, 0u25e1); Clear() # ◠◡
    Select(0u25e2, 0u25e5); Clear() # ◢◣◤◥
    Select(0u25ef); Clear() # ◯
    Select(0u2600, 0u2603); Clear() # ☀☁☂☃
    Select(0u2605, 0u2606); Clear() # ★☆
    Select(0u260e); Clear() # ☎
    Select(0u2610, 0u2612); Clear() # ☐☑☒
    Select(0u2616, 0u2617); Clear() # ☖☗
    Select(0u261c, 0u261f); Clear() # ☜☝☞☟
    Select(0u263c); Clear() # ☼
    Select(0u2660, 0u266f); Clear() # ♠-♯
    Select(0u2702); Clear() # ✂
    Select(0u2756); Clear() # ❖
    Select(0u27a1); Clear() # ➡
    Select(0ue000, 0uf8ff)
    if ("${liga_flag}" == "true")
        SelectFewer(0ue100, 0ue129) # リガチャ
    endif
    Clear() # 私用領域
    Select(1114112, 1114344); Clear() # 異体字等

# --------------------------------------------------

# Proccess before saving
    Print("Process before saving")
    if (0 < SelectIf(".notdef"))
        Clear(); DetachAndRemoveGlyphs()
    endif
    RemoveDetachedGlyphs()
    if ("${draft_flag}" == "true")
        SelectWorthOutputting()
        RoundToInt()
    endif

# --------------------------------------------------

# Save modified latin font
    Print("Save " + output_list[i])
    Save("${tmpdir}/" + output_list[i])
 #    Generate("${tmpdir}/" + output_list[i], "", 0x04)
 #    Generate("${tmpdir}/" + output_list[i], "", 0x84)
    Close()
    Print("")

    i += 1
endloop

Quit()
_EOT_

################################################################################
# Generate script for custom fonts
################################################################################

cat > ${tmpdir}/${custom_font_generator} << _EOT_
#!$fontforge_command -script

Print("- Generate custom fonts -")

# Set parameters
latin_sfd_list    = ["${tmpdir}/${modified_latin_regular}", \\
                     "${tmpdir}/${modified_latin_bold}"]
base_ttf_list     = ["${input_base_regular}", "${input_base_bold}"]
fontfamily        = "${font_familyname}"
fontfamilysuffix  = "${font_familyname_suffix}"
fontstyle_list    = ["Regular", "Bold"]
fontweight_list   = [400,       700]
panoseweight_list = [5,         8]
if ("${nerd_flag}" == "true") # なぜか後で上書きすると失敗することがあったためここで設定
    copyright     = "${copyright}" \\
                  + "${copyright_nerd_fonts}" \\
                  + "${copyright_license}"
else
    copyright     = "${copyright}" \\
                  + "${copyright_license}"
endif
version           = "${font_version}"

# Begin loop of regular and bold
i = 0
while (i < SizeOf(fontstyle_list))
# Open new file
    Print("Create new file")
    New()

# Set encoding to Unicode-bmp
    Reencode("unicode")

# Set configuration
 #    if (fontfamilysuffix != "") # パッチを当てる時にSuffixを追加するので無効化
 #        SetFontNames(fontfamily + fontfamilysuffix + "-" + fontstyle_list[i], \\
 #                     fontfamily + " " + fontfamilysuffix, \\
 #                     fontfamily + " " + fontfamilysuffix + " " + fontstyle_list[i], \\
 #                     fontstyle_list[i], \\
 #                     copyright, version)
 #    else
        SetFontNames(fontfamily + "-" + fontstyle_list[i], \\
                     fontfamily, \\
                     fontfamily + " " + fontstyle_list[i], \\
                     fontstyle_list[i], \\
                     copyright, version)
 #    endif
    SetTTFName(0x409, 2, fontstyle_list[i])
    SetTTFName(0x409, 3, "FontForge ${fontforge_version} : " + "FontTools ${ttx_version} : " + \$fullname + " : " + Strftime("%d-%m-%Y", 0))
    ScaleToEm(${em_ascent1024}, ${em_descent1024})
    SetOS2Value("Weight", fontweight_list[i]) # Book or Bold
    SetOS2Value("Width",                   5) # Medium
    SetOS2Value("FSType",                  0)
    SetOS2Value("VendorID",   "${vendor_id}")
    SetOS2Value("IBMFamily",            2057) # SS Typewriter Gothic
    SetOS2Value("WinAscentIsOffset",       0)
    SetOS2Value("WinDescentIsOffset",      0)
    SetOS2Value("TypoAscentIsOffset",      0)
    SetOS2Value("TypoDescentIsOffset",     0)
    SetOS2Value("HHeadAscentIsOffset",     0)
    SetOS2Value("HHeadDescentIsOffset",    0)
    SetOS2Value("WinAscent",             ${win_ascent1024})
    SetOS2Value("WinDescent",            ${win_descent1024})
    SetOS2Value("TypoAscent",            ${typo_ascent1024})
    SetOS2Value("TypoDescent",          -${typo_descent1024})
    SetOS2Value("TypoLineGap",           ${typo_linegap1024})
    SetOS2Value("HHeadAscent",           ${hhea_ascent1024})
    SetOS2Value("HHeadDescent",         -${hhea_descent1024})
    SetOS2Value("HHeadLineGap",          ${hhea_linegap1024})
    SetPanose([2, 11, panoseweight_list[i], 9, 2, 2, 3, 2, 2, 7])

# Merge fonts
    Print("Merge " + latin_sfd_list[i]:t \\
          + " with " + base_ttf_list[i]:t)
    MergeFonts(latin_sfd_list[i])
    MergeFonts(base_ttf_list[i])

# --------------------------------------------------

# 使用しないグリフクリア
    Print("Remove not used glyphs")
    Select(0, 31); Clear(); DetachAndRemoveGlyphs()

# Clear kerns, position, substitutions
    Print("Clear kerns, position, substitutions")
    RemoveAllKerns()

    lookups = GetLookups("GSUB"); numlookups = SizeOf(lookups); j = 0
    while (j < numlookups)
        if (${lookupIndex_calt} + 1 <= j) # sups フィーチャが重複するため + 1
            Print("Remove " + lookups[j])
            RemoveLookup(lookups[j])
        elseif (j == 2 + ${lookupIndex_liga_end}) # Cyroit側の sups フィーチャを削除
            Print("Remove " + lookups[j])
            RemoveLookup(lookups[j])
        endif
        j++
    endloop

    lookups = GetLookups("GPOS"); numlookups = SizeOf(lookups); j = 0
    while (j < numlookups)
        Print("Remove GPOS_" + lookups[j])
        RemoveLookup(lookups[j]); j++
    endloop

# Clear instructions, hints
    Print("Clear instructions, hints")
    SelectWorthOutputting()
    ClearInstrs()
    ClearHints()

# --------------------------------------------------

# Proccess before saving
    Print("Process before saving")
    if (0 < SelectIf(".notdef"))
        Clear(); DetachAndRemoveGlyphs()
    endif
    RemoveDetachedGlyphs()
    SelectWorthOutputting()
 #    RemoveOverlap()
    RoundToInt()
 #    AutoHint()
 #    AutoInstr()

# --------------------------------------------------

# Save custom font
    if (fontfamilysuffix != "")
        Print("Save " + fontfamily + fontfamilysuffix + "-" + fontstyle_list[i] + ".ttf")
        Generate(fontfamily + fontfamilysuffix + "-" + fontstyle_list[i] + ".ttf", "", 0x04)
 #        Generate(fontfamily + fontfamilysuffix + "-" + fontstyle_list[i] + ".ttf", "", 0x84)
    else
        Print("Save " + fontfamily + "-" + fontstyle_list[i] + ".ttf")
        Generate(fontfamily + "-" + fontstyle_list[i] + ".ttf", "", 0x04)
 #        Generate(fontfamily + "-" + fontstyle_list[i] + ".ttf", "", 0x84)
    endif
    Close()
    Print("")

    i += 1
endloop

Quit()
_EOT_

################################################################################
# Generate script for modified Nerd fonts
################################################################################

cat > ${tmpdir}/${modified_nerd_generator} << _EOT_
#!$fontforge_command -script

Print("- Generate modified Nerd fonts -")

# Set parameters
input_list  = ["${input_nerd}"]
output_list = ["${modified_nerd}"]

# Begin loop of regular and bold
i = 0
while (i < SizeOf(input_list))
# Open nerd fonts
    Print("Open " + input_list[i])
    Open(input_list[i])
    SelectWorthOutputting()
    UnlinkReference()
    ScaleToEm(${em_ascent1024}, ${em_descent1024})
    SetOS2Value("WinAscent",             ${win_ascent1024})
    SetOS2Value("WinDescent",            ${win_descent1024})
    SetOS2Value("TypoAscent",            ${typo_ascent1024})
    SetOS2Value("TypoDescent",          -${typo_descent1024})
    SetOS2Value("TypoLineGap",           ${typo_linegap1024})
    SetOS2Value("HHeadAscent",           ${hhea_ascent1024})
    SetOS2Value("HHeadDescent",         -${hhea_descent1024})
    SetOS2Value("HHeadLineGap",          ${hhea_linegap1024})

# --------------------------------------------------

# 使用しないグリフクリア
    Print("Remove not used glyphs")
    Select(0, 31); Clear(); DetachAndRemoveGlyphs()
    Select(1114112, 1114114); Clear(); DetachAndRemoveGlyphs()

# Clear kerns, position, substitutions
    Print("Clear kerns, position, substitutions")
    RemoveAllKerns()

 #    lookups = GetLookups("GSUB"); numlookups = SizeOf(lookups); j = 0
 #    while (j < numlookups)
 #        Print("Remove GSUB_" + lookups[j])
 #        RemoveLookup(lookups[j]); j++
 #    endloop

 #    lookups = GetLookups("GPOS"); numlookups = SizeOf(lookups); j = 0
 #    while (j < numlookups)
 #        Print("Remove GPOS_" + lookups[j])
 #        RemoveLookup(lookups[j]); j++
 #    endloop

# Clear instructions, hints
    Print("Clear instructions, hints")
    SelectWorthOutputting()
    ClearInstrs()
    ClearHints()

# Proccess before editing
    if ("${draft_flag}" == "false")
        Print("Process before editing (it may take a few minutes)")
        SelectWorthOutputting()
        RemoveOverlap()
        CorrectDirection()
    endif

# --------------------------------------------------

# 全て少し移動
    Print("Move all glyphs")
    SelectWorthOutputting(); Move(0, ${move_y_nerd})

# IEC Power Symbols
    Print("Edit IEC Power Symbols")
    Select(0u23fb, 0u23fe)
    SelectMore(0u2b58)
    Scale(${scale_nerd})
    SetWidth(1024)

# Pomicons
    Print("Edit Pomicons")
    Select(0ue000, 0ue00a)
    Scale(${scale_pomicons})
    SetWidth(1024)

# Powerline Glyphs (Win(HHead)Ascent から Win(HHead)Descent までの長さを基準として大きさと位置を合わせる)
    Print("Edit Powerline Extra Symbols")
    Select(0ue0a0, 0ue0a3)
    SelectMore(0ue0b0, 0ue0c8)
    SelectMore(0ue0ca)
    SelectMore(0ue0cc, 0ue0d2)
    SelectMore(0ue0d4)
    SelectMore(0ue0d6, 0ue0d7)
    Move(0, -${move_y_nerd}) # 元の位置に戻す
    Move(0, ${move_y_em_revise}) # em値変更でのズレ修正
    Select(0ue0a0);         Move(-226, ${move_y_pl}); SetWidth(512)
    Select(0ue0a1, 0ue0a3); Move(-256, ${move_y_pl}); SetWidth(512)
    Select(0ue0b0);         Scale(70,  ${scale_height_pl}, 0,    ${center_height_pl}); Move(9,  ${move_y_pl}); SetWidth(512)
    Select(0ue0b1);         Scale(70,  ${scale_height_pl}, 0,    ${center_height_pl}); Move(0,  ${move_y_pl}); SetWidth(512)
    Select(0ue0b2);         Scale(70,  ${scale_height_pl}, 1024, ${center_height_pl}); Move(-512 - 9,  ${move_y_pl}); SetWidth(512)
    Select(0ue0b3);         Scale(70,  ${scale_height_pl}, 1024, ${center_height_pl}); Move(-512,      ${move_y_pl}); SetWidth(512)
    Select(0ue0b4);         Scale(80,  ${scale_height_pl}, 0,    ${center_height_pl}); Move(18, ${move_y_pl}); SetWidth(512)
    Select(0ue0b5);         Scale(95,  ${scale_height_pl}, 0,    ${center_height_pl}); Move(0,  ${move_y_pl}); SetWidth(512)
    Select(0ue0b6);         Scale(80,  ${scale_height_pl}, 1024, ${center_height_pl}); Move(-512 - 18, ${move_y_pl}); SetWidth(512)
    Select(0ue0b7);         Scale(95,  ${scale_height_pl}, 1024, ${center_height_pl}); Move(-512,      ${move_y_pl}); SetWidth(512)
    Select(0ue0b8);         Scale(50,  ${scale_height_pl}, 0,    ${center_height_pl}); Move(-8,  ${move_y_pl}); SetWidth(512)
    Select(0ue0b9);         Scale(50,  ${scale_height_pl}, 0,    ${center_height_pl}); Move(0,  ${move_y_pl}); SetWidth(512)
    Select(0ue0ba);         Scale(50,  ${scale_height_pl}, 1024, ${center_height_pl}); Move(-512 + 8,  ${move_y_pl}); SetWidth(512)
    Select(0ue0bb);         Scale(50,  ${scale_height_pl}, 1024, ${center_height_pl}); Move(-512,      ${move_y_pl}); SetWidth(512)
    Select(0ue0bc);         Scale(50,  ${scale_height_pl}, 0,    ${center_height_pl}); Move(-8,  ${move_y_pl}); SetWidth(512)
    Select(0ue0bd);         Scale(50,  ${scale_height_pl}, 0,    ${center_height_pl}); Move(0,  ${move_y_pl}); SetWidth(512)
    Select(0ue0be);         Scale(50,  ${scale_height_pl}, 1024, ${center_height_pl}); Move(-512 + 8,  ${move_y_pl}); SetWidth(512)
    Select(0ue0bf);         Scale(50,  ${scale_height_pl}, 1024, ${center_height_pl}); Move(-512,      ${move_y_pl}); SetWidth(512)
    Select(0ue0c0, 0ue0c1); Scale(95,  ${scale_height_pl}, 0,    ${center_height_pl}); Move(0, ${move_y_pl2}); SetWidth(1024)
    Select(0ue0c2, 0ue0c3); Scale(95,  ${scale_height_pl}, 1024, ${center_height_pl}); Move(0, ${move_y_pl2}); SetWidth(1024)
    Select(0ue0c4);         Scale(105, ${scale_height_pl}, 0,    ${center_height_pl}); Move(0, ${move_y_pl}); SetWidth(1024)
    Select(0ue0c5);         Scale(105, ${scale_height_pl}, 1024, ${center_height_pl}); Move(0, ${move_y_pl}); SetWidth(1024)
    Select(0ue0c6);         Scale(105, ${scale_height_pl}, 0,    ${center_height_pl}); Move(0, ${move_y_pl}); SetWidth(1024)
    Select(0ue0c7);         Scale(105, ${scale_height_pl}, 1024, ${center_height_pl}); Move(0, ${move_y_pl}); SetWidth(1024)
    Select(0ue0c8);         Scale(95,  ${scale_height_pl}, 0,    ${center_height_pl}); Move(0, ${move_y_pl}); SetWidth(1024)
    Select(0ue0ca);         Scale(95,  ${scale_height_pl}, 1024, ${center_height_pl}); Move(0, ${move_y_pl}); SetWidth(1024)
    Select(0ue0cc);         Scale(105, ${scale_height_pl}, 0,    ${center_height_pl}); Move(0, ${move_y_pl}); SetWidth(1024)
    Select(0ue0cd);         Scale(105, ${scale_height_pl2}, 0,   ${center_height_pl}); Move(-21, ${move_y_pl}); SetWidth(1024)
    Select(0ue0ce, 0ue0d0); Move(0, ${move_y_pl}); SetWidth(1024)
    Select(0ue0d1);         Scale(105, ${scale_height_pl2}, 0,   ${center_height_pl}); Move(-21, ${move_y_pl}); SetWidth(1024)
    Select(0ue0d2);         Scale(105, ${scale_height_pl}, 0,    ${center_height_pl}); Move(0, ${move_y_pl}); SetWidth(1024)
    Select(0ue0d4);         Scale(105, ${scale_height_pl}, 1024, ${center_height_pl}); Move(0, ${move_y_pl});SetWidth(1024)
    Select(0ue0d6);         Scale(105, ${scale_height_pl}, 0,    ${center_height_pl}); Move( 33, ${move_y_pl}); SetWidth(1024)
    Select(0ue0d7);         Scale(105, ${scale_height_pl}, 1024, ${center_height_pl}); Move(-33, ${move_y_pl});SetWidth(1024)

    # Loose 版対応
    if ("${loose_flag}" == "true")
        Select(0ue0b0, 0ue0b1)
        SelectMore(0ue0b4)
        SelectMore(0ue0b5)
        SelectMore(0ue0b8, 0ue0b9)
        SelectMore(0ue0bc, 0ue0bd)
        SetWidth(${width_hankaku})

        Select(0ue0b2, 0ue0b3)
        SelectMore(0ue0b6)
        SelectMore(0ue0b7)
        SelectMore(0ue0ba, 0ue0bb)
        SelectMore(0ue0be, 0ue0bf)
        Move(${move_x_hankaku} * 2, 0)
        SetWidth(${width_hankaku})
    endif

# Font Awesome Extension
    Print("Edit Font Awesome Extension")
    Select(0ue200, 0ue2a9)
    Scale(${scale_nerd})
    SetWidth(1024)

# Weather Icons
    Print("Edit Weather Icons")
    Select(0ue339)
    SelectMore(0ue340, 0ue341)
    SelectMore(0ue344)
    SelectMore(0ue348, 0ue349)
    SelectMore(0ue34e)
    SelectMore(0ue350)
    SelectMore(0ue353, 0ue35b)
    SelectMore(0ue381, 0ue3a9)
    SelectMore(0ue3af, 0ue3bb)
    SelectMore(0ue3c4, 0ue3e3)
    Scale(${scale_nerd})
    SetWidth(1024)

    Select(0ue300, 0ue3e3)
    SetWidth(1024)

# Seti-UI + Customs
    Print("Edit Seti-UI + Costoms")
    Select(0ue5fa, 0ue6b8)
    Scale(${scale_nerd})
    SetWidth(1024)

# Devicons
    Print("Edit Devicons")
    Select(0ue700, 0ue8ef)
    Scale(${scale_nerd})
    SetWidth(1024)

# Codicons
    Print("Edit Codicons")
    j = 0uea60
    while (j <= 0uec1e)
        Select(j)
        if (WorthOutputting())
            Scale(${scale_nerd})
            SetWidth(1024)
        endif
        j += 1
    endloop

# Font Awesome
    Print("Edit Font Awesome")
    Select(0ued00, 0uedff)
    SelectMore(0uee0c, 0uefce)
    SelectMore(0uf000, 0uf2ff)
    Scale(${scale_nerd})
    SetWidth(1024)

# Font Logos
    Print("Edit Font Logos")
    Select(0uf300, 0uf381)
    Scale(${scale_nerd})
    SetWidth(1024)

# Octicons
    Print("Edit Octicons")
    Select(0u26a1)
    SelectMore(0uf400, 0uf533)
    Scale(${scale_nerd})
    SetWidth(1024)

# Material Design Icons
    Print("Edit Material Design Icons")
 #    Select(0uf500, 0uf8ff); Scale(83); SetWidth(1024) # v2.3.3まで 互換用
    Select(0uf0001, 0uf1af0)
    Scale(${scale_nerd})
    SetWidth(1024)

# Others
    Print("Edit Other glyphs")
    Select(0u2630); Scale(${scale_nerd}); SetWidth(1024)
    Select(0u276c, 0u2771) #; Scale(${scale_nerd}) # 縮小しない
    SetWidth(1024)

#  (Mac用)
    Select(0ue711); Copy() # 
    Select(0uf8ff); Paste() #  (私用領域)

# --------------------------------------------------

# Proccess before saving
    Print("Process before saving")
    if (0 < SelectIf(".notdef"))
        Clear(); DetachAndRemoveGlyphs()
    endif
    RemoveDetachedGlyphs()
    SelectWorthOutputting()
    RoundToInt()

# --------------------------------------------------

# Save modified nerd fonts (sfdで保存するとmergeしたときに一部のグリフが消える)
    Print("Save " + output_list[i])
 #    Save("${tmpdir}/" + output_list[i])
    Generate("${tmpdir}/" + output_list[i], "", 0x04)
 #    Generate("${tmpdir}/" + output_list[i], "", 0x84)
    Close()
    Print("")

    i += 1
endloop

Quit()
_EOT_

################################################################################
# Generate script to merge with Nerd fonts
################################################################################
cat > ${tmpdir}/${merged_nerd_generator} << _EOT_
#!$fontforge_command -script

# Set parameters
input_nerd = "${tmpdir}/${modified_nerd}"
copyright     = "${copyright}" \\
              + "${copyright_nerd_fonts}" \\
              + "${copyright_license}"

usage = "Usage: ${merged_nerd_generator} fontfamily-fontstyle.ttf ..."

# Get arguments
if (\$argc == 1)
    Print(usage)
    Quit()
endif

Print("- Merge with Nerd fonts -")

# Begin loop
i = 1
while (i < \$argc)

# Check filename
    input_ttf = \$argv[i]
    input     = input_ttf:t:r # :t:r ファイル名のみ抽出
    if (input_ttf:t:e != "ttf") # :t:e 拡張子のみ抽出
        Print(usage)
        Quit()
    endif

    hypen_index = Strrstr(input, '-') # '-'を後ろから探す('-'から前の文字数を取得)
    if (hypen_index == -1)
        Print(usage)
        Quit()
    endif

# Get parameters
    input_family = Strsub(input, 0, hypen_index) # ファミリー名を取得
    input_style  = Strsub(input, hypen_index + 1) # スタイル名を取得

    output_family = input_family
    output_style = input_style

# Open file and set configuration
    Print("Open " + input_ttf)
    Open(input_ttf)

    SetFontNames("", "", "", "", copyright)

# Merge with nerd fonts
    Print("Merge " + input_ttf \\
          + " with " + input_nerd:t)
    MergeFonts(input_nerd)

# --------------------------------------------------

# ブロック要素を加工 (Powerline対応)
    Print("Edit box drawing and block")
    Select(0u2580, 0u259f)
    Scale(100, ${scale_height_block}, 0, ${center_height_pl}) # Powerlineに合わせて縦を縮小
    Move(0, ${move_y_pl})

    Select(0ue0d1); RemoveOverlap(); Copy() # 
    Select(65552); Paste() # Temporary glyph
    if ("${loose_flag}" == "true") # Loose 版対応
        Scale(113, 100, 256, ${center_height_hankaku})
    endif
    Copy()
    j = 0
    while (j < 32)
        Select(0u2580 + j); PasteInto()
        if ("${draft_flag}" == "false")
            OverlapIntersect()
        endif
        SetWidth(${width_hankaku})
        j += 1
    endloop

    Select(65552); Clear() # Temporary glyph

# 八卦
    Print("Edit bagua trigrams")
    Select(0u2630); Copy() # ☰
    Select(0u2631, 0u2637); Paste() # ☱-☷
    # 線を分割するスクリーン
    Select(${address_store_b_diagram} + 2); Copy() # 保管した■
    Select(65552, 65555); Paste() # Temporary glyph
    Scale(150)
    Select(65552)
    Move(0,700)
    Select(0u2630); Copy() # ☰
    Select(65552); PasteInto()
    OverlapIntersect()
    Scale(25, 100)
    Rotate(90)
    VFlip()
    Copy()
    Select(65553); PasteInto()
    Select(65554); PasteWithOffset(0, -330)
    Select(65555); PasteWithOffset(0, -650)
    # 合成
    Select(65553); Copy()
    Select(0u2631); PasteInto(); OverlapIntersect() # ☱
    Select(0u2633); PasteInto(); OverlapIntersect() # ☳
    Select(0u2635); PasteInto(); OverlapIntersect() # ☵
    Select(0u2637); PasteInto(); OverlapIntersect() # ☷
    Select(65554); Copy()
    Select(0u2632); PasteInto(); OverlapIntersect() # ☲
    Select(0u2633); PasteInto(); OverlapIntersect() # ☳
    Select(0u2636); PasteInto(); OverlapIntersect() # ☶
    Select(0u2637); PasteInto(); OverlapIntersect() # ☷
    Select(65555); Copy()
    Select(0u2634); PasteInto(); OverlapIntersect() # ☴
    Select(0u2635); PasteInto(); OverlapIntersect() # ☵
    Select(0u2636); PasteInto(); OverlapIntersect() # ☶
    Select(0u2637); PasteInto(); OverlapIntersect() # ☷
    Select(0u2630, 0u2637); SetWidth(1024)

    Select(65552, 65555); Clear() # Temporary glyph

# --------------------------------------------------

# Proccess before saving
    Print("Process before saving")
    if (0 < SelectIf(".notdef"))
        Clear(); DetachAndRemoveGlyphs()
    endif
    RemoveDetachedGlyphs()
    SelectWorthOutputting()
    RoundToInt()

# --------------------------------------------------

# Save merged font
    Print("Save " + output_family + "-" + output_style + ".ttf")
    Generate(output_family + "-" + output_style + ".ttf", "", 0x04)
 #    Generate(output_family + "-" + output_style + ".ttf", "", 0x84)
    Close()
    Print("")

    i += 1
endloop

Quit()
_EOT_

################################################################################
# Generate script to modify font parameters
################################################################################
cat > ${tmpdir}/${parameter_modificator} << _EOT_
#!$fontforge_command -script

usage = "Usage: ${parameter_modificator} fontfamily-fontstyle.ttf ..."

# Get arguments
if (\$argc == 1)
    Print(usage)
    Quit()
endif

Print("- Modify font parameters -")

# Begin loop
i = 1
while (i < \$argc)

# Check filename
    input_ttf = \$argv[i]
    input     = input_ttf:t:r # :t:r ファイル名のみ抽出
    if (input_ttf:t:e != "ttf") # :t:e 拡張子のみ抽出
        Print(usage)
        Quit()
    endif

    hypen_index = Strrstr(input, '-') # '-'を後ろから探す('-'から前の文字数を取得)
    if (hypen_index == -1)
        Print(usage)
        Quit()
    endif

# Open file and set configuration
    Print("Open " + input_ttf)
    Open(input_ttf)

# --------------------------------------------------

# スペースの width 変更
    Print("Modified space width")

    Select(0u2001) # em quad
    SelectMore(0u2003) # em space
    SetWidth(${width_zenkaku})

    Select(0u2000) # en quad
    SelectMore(0u2002) # en space
    SelectMore(0u2004) # three-per-em space
    SelectMore(0u2005) # four-per-em space
    SelectMore(0u2006) # six-per-em space
    SelectMore(0u2007) # figure space
    SelectMore(0u2008) # punctuation space
    SelectMore(0u2009) # thin space
    SelectMore(0u200a) # hair space
    SelectMore(0u202f) # narrow no-break space
    SelectMore(0u205f) # medium mathematical space
    SetWidth(${width_hankaku})

    Select(0u034f) # combining grapheme joiner
    SelectMore(0u200b) # zero width space
    SelectMore(0u200c) # zero width non-joiner
    SelectMore(0u200d) # zero width joiner
    SelectMore(0u2060) # word joiner
    SelectMore(0ufeff) # zero width no-break space
    SetWidth(0)

# 記号のグリフを加工
    Print("Edit symbols")
# 🄯 (追加、合成前に実行するとエラーが出る)
    Select(0u00a9); Copy() # ©
    Select(0u1f12f); Paste() # 🄯
    HFlip()
    CorrectDirection()
    SetWidth(${width_hankaku})

# ＿ (latin フォントの _ に合わせる)
    Select(0uff3f) # ＿
    Move(0, ${move_y_zenkaku_underbar})
    SetWidth(${width_zenkaku})

# 演算子を上下に移動
    math = [0u2243, 0u2252, 0u223c] # ≃≒∼
 #    math = [0u2243, 0u2248, 0u2252, 0u223c] # ≃≈≒∼
    j = 0
    while (j < SizeOf(math))
        Select(math[j]);
        Move(0, ${move_y_math} + ${move_y_zenkaku_math})
    SetWidth(${width_hankaku})
        j += 1
    endloop

    math = [0u226a, 0u226b] # ≪≫
    j = 0
    while (j < SizeOf(math))
        Select(math[j]);
        Move(0, ${move_y_math} + ${move_y_zenkaku_math})
        SetWidth(${width_zenkaku})
        j += 1
    endloop

# --------------------------------------------------

# 全角形加工 (半角英数記号を全角形にコピーし、下線を追加)
    Print("Copy hankaku to zenkaku and edit")

    # 縦線作成
 #    Select(${address_store_underline}); Copy() # 保管した全角下線
 #    Select(${address_store_underline} + 2); Paste() # 保管所 (後で使うために保管)
 #    Rotate(-90, 512, 315)
 #    Move(-13, 0)
 #    SetWidth(${width_zenkaku})

# 半角英数記号を全角形にコピー、加工
    # ! - }
    j = 0
    while (j < 93)
        if (j != 62\
         && j !=  7 && j != 58 && j != 90\
         && j !=  8 && j != 60 && j != 92\
         && j != 11 && j != 13) # ＿ （［｛ ）］｝ ，．
          if (j == 91)
            Select(${address_store_visi_latin} + 1) # ｜ (全角縦棒を実線にする)
          else
            Select(0u0021 + j)
          endif
          Copy()
          Select(0uff01 + j); Paste()
          Move(256 - ${move_x_hankaku}, 0)
        endif
 #        if (j == 7 || j == 58 || j == 90) # （ ［ ｛
 #            Move(128 - ${move_x_hankaku}, 0)
 #        elseif (j == 8 || j == 60 || j == 92) # ） ］ ｝
 #            Move(-128 + ${move_x_hankaku}, 0)
 #        elseif (j == 11 || j == 13) # ， ．
 #            Move(-256 + ${move_x_hankaku}, 0)
 #        endif
        SetWidth(${width_zenkaku})
        j += 1
    endloop

    # 〜
 #    Select(0uff5e); Rotate(10) # ～
 #    SetWidth(${width_zenkaku})

    # ￠ - ￦
    Select(0u00a2);  Copy() # ¢
    Select(0uffe0); Paste() # ￠
    Move(256 - ${move_x_hankaku}, 0)
    SetWidth(${width_zenkaku})
    Select(0u00a3);  Copy() # £
    Select(0uffe1); Paste() # ￡
    Move(256 - ${move_x_hankaku}, 0)
    SetWidth(${width_zenkaku})
    Select(0u00ac);  Copy() # ¬
    Select(0uffe2); Paste() # ￢
    Move(256 - ${move_x_hankaku}, 0)
    SetWidth(${width_zenkaku})
 #    Select(0u00af);  Copy() # ¯
 #    Select(0uffe3); Paste() # ￣
 #    Move(256 - ${move_x_hankaku}, 0)
 #    SetWidth(${width_zenkaku})
    Select(0u00a6);  Copy() # ¦
    Select(0uffe4); Paste() # ￤
    Move(256 - ${move_x_hankaku}, 0)
    SetWidth(${width_zenkaku})
    Select(0u00a5);  Copy() # ¥
    Select(0uffe5); Paste() # ￥
    Move(256 - ${move_x_hankaku}, 0)
    SetWidth(${width_zenkaku})
    Select(0u20a9);  Copy() # ₩
    Select(0uffe6); Paste() # ￦
    Move(256 - ${move_x_hankaku}, 0)
    SetWidth(${width_zenkaku})

    # ‼
    Select(0u0021); Copy() # !
    Select(0u203c); Paste() # ‼
    Move(76, 0)
    Select(0u203c); PasteWithOffset(436, 0) # ‼
    Move(-${move_x_hankaku}, 0)
    SetWidth(${width_zenkaku})

    # ⁇
    Select(0u003F); Copy() # ?
    Select(0u2047); Paste() # ⁇
    Move(60, 0)
    Select(0u2047); PasteWithOffset(476, 0) # ⁇
    Move(-${move_x_hankaku}, 0)
    SetWidth(${width_zenkaku})

    # ⁈
    Select(0u003F); Copy() # ?
    Select(0u2048); Paste() # ⁈
    Move(88, 0)
    Select(0u0021); Copy() # !
    Select(0u2048); PasteWithOffset(436, 0) # ⁈
    Move(-${move_x_hankaku}, 0)
    SetWidth(${width_zenkaku})

    # ⁉
    Select(0u0021); Copy() # !
    Select(0u2049); Paste() # ⁉
    Move(76, 0)
    Select(0u003F); Copy() # ?
    Select(0u2049); PasteWithOffset(448, 0) # ⁉
    Move(-${move_x_hankaku}, 0)
    SetWidth(${width_zenkaku})

# 縦書き形句読点
 #    hori = [0uff0c, 0u3001, 0u3002] # ，、。
 #    vert = 0ufe10
 #    j = 0
 #    while (j < SizeOf(hori))
 #        Select(hori[j]); Copy()
 #        Select(vert + j); Paste()
 #        if (hori[j] == 0uff0c)
 #            Move(542, 597)
 #        else
 #            Move(594, 546)
 #        endif
 #        SetWidth(${width_zenkaku})
 #        j += 1
 #    endloop

# CJK互換形下線
 #    Select(0uff3f); Copy() # ＿
 #    Select(0ufe33); Paste() # ︳
 #    Rotate(-90, 512, 315)
 #    Move(-13, 0)
 #    SetWidth(${width_zenkaku})

# CJK互換形括弧
 #    hori = [0u3016, 0u3017] # 〖〗
 #    vert = 0ufe17 # ︗
 #    j = 0
 #    while (j < SizeOf(hori))
 #        Select(hori[j]); Copy()
 #        Select(vert + j); Paste()
 #        Rotate(-90, 512, 315)
 #        Move(-20, 0)
 #        SetWidth(${width_zenkaku})
 #        j += 1
 #    endloop
 #
 #    hori = [0uff08, 0uff09, 0uff5b, 0uff5d,\
 #            0u3014, 0u3015, 0u3010, 0u3011,\
 #            0u300a, 0u300b, 0u3008, 0u3009,\
 #            0u300c, 0u300d, 0u300e, 0u300f] # （）｛｝ 〔〕【】 《》〈〉 「」『』
 #    vert = 0ufe35 # ︵
 #    j = 0
 #    while (j < SizeOf(hori))
 #        Select(hori[j]); Copy()
 #        Select(vert + j); Paste()
 #        Rotate(-90, 512, 315)
 #        if (hori[j] == 0uff08 || hori[j] == 0uff09) # （）
 #            Move(-9, 0)
 #        elseif (hori[j] == 0uff5b || hori[j] == 0uff5d) # ｛｝
 #            Move(3, 0)
 #        else
 #            Move(-20, 0)
 #        endif
 #        SetWidth(${width_zenkaku})
 #        j += 1
 #    endloop
 #
 #    hori = [0uff3b, 0uff3d] # ［］
 #    vert = 0ufe47 # ﹇
 #    j = 0
 #    while (j < SizeOf(hori))
 #        Select(hori[j]); Copy()
 #        Select(vert + j); Paste()
 #        Rotate(-90, 512, 315)
 #        Move(2, 0)
 #        SetWidth(${width_zenkaku})
 #        j += 1
 #    endloop

# 縦書き用全角形他 (vertフィーチャ用)
    Print("Edit vert glyphs")
    k = 0
    hori = [0uff08, 0uff09, 0uff0c, 0uff0e,\
            0uff1a, 0uff1d, 0uff3b, 0uff3d,\
            0uff3f, 0uff5b, 0uff5c, 0uff5d,\
            0uff5e, 0uffe3, 0uff0d, 0uff1b,\
            0uff1c, 0uff1e, 0uff5f, 0uff60] # （），． ：＝［］ ＿｛｜｝ ～￣－； ＜＞｟｠
    vert = ${address_vert_start}
    j = 0
    while (j < SizeOf(hori))
        if (hori[j] != 0uff0c && hori[j] != 0uff0e\
         && hori[j] != 0uff08 && hori[j] != 0uff09\
         && hori[j] != 0uff5b && hori[j] != 0uff5d\
         && hori[j] != 0uff3b && hori[j] != 0uff3d\
         && hori[j] != 0uff5f && hori[j] != 0uff60\
         && hori[j] != 0uff3f\
         && hori[j] != 0uffe3\
         && hori[j] != 0uff5e) # ，． （） ｛｝ ［］ ｟｠ ＿ ￣ ～
            Select(hori[j]); Copy()
            Select(vert + j); Paste()
            if (hori[j] == 0uff0c || hori[j] == 0uff0e) # ， ．
                Move(542, 597)
            else
                Rotate(-90, 512, 315)
                if (hori[j] == 0uff08 || hori[j] == 0uff09) # （）
                    Move(-9, 0)
                elseif (hori[j] == 0uff5b || hori[j] == 0uff5d) # ｛｝
                    Move(3, 0)
                elseif (hori[j] == 0uff3b || hori[j] == 0uff3d) # ［］
                    Move(2, 0)
                elseif (hori[j] == 0uff5f || hori[j] == 0uff60) # ｟｠
                    Move(-20, 0)
                elseif (hori[j] == 0uff3f) # ＿
                    Move(-13, 0)
                elseif (hori[j] == 0uffe3) # ￣
                    Move(13 + 90 - ${move_y_zenkaku_underbar}, 0)
                elseif (hori[j] == 0uff5e) # ～
                    Move(13, 0)
                elseif (hori[j] == 0uff1a || hori[j] == 0uff1b) # ：；
                    Move(${move_x_vert_colon}, 0)
                elseif (hori[j] == 0uff5c) # ｜
                    Move(${move_x_vert_bar}, 0)
                else # ＝－＜＞
                    Move(${move_x_vert_math}, 0)
                endif
            endif
            Copy(); Select(${address_store_vert} + k); Paste(); SetWidth(${width_zenkaku}) # 保管所にコピー
            Select(${address_store_underline} + 2);  Copy() # 縦線追加
            Select(vert + j); PasteInto()
            SetWidth(${width_zenkaku})
        endif
        j += 1
        k += 1
    endloop

    hori = [0u309b, 0u309c,\
            0uff0f, 0uff3c,\
            0uff01, 0uff02, 0uff03, 0uff04,\
            0uff05, 0uff06, 0uff07, 0uff0a,\
            0uff0b, 0uff10, 0uff11, 0uff12,\
            0uff13, 0uff14, 0uff15, 0uff16,\
            0uff17, 0uff18, 0uff19, 0uff1f,\
            0uff20, 0uff21, 0uff22, 0uff23,\
            0uff24, 0uff25, 0uff26, 0uff27,\
            0uff28, 0uff29, 0uff2a, 0uff2b,\
            0uff2c, 0uff2d, 0uff2e, 0uff2f,\
            0uff30, 0uff31, 0uff32, 0uff33,\
            0uff34, 0uff35, 0uff36, 0uff37,\
            0uff38, 0uff39, 0uff3a, 0uff3e,\
            0uff40, 0uff41, 0uff42, 0uff43,\
            0uff44, 0uff45, 0uff46, 0uff47,\
            0uff48, 0uff49, 0uff4a, 0uff4b,\
            0uff4c, 0uff4d, 0uff4e, 0uff4f,\
            0uff50, 0uff51, 0uff52, 0uff53,\
            0uff54, 0uff55, 0uff56, 0uff57,\
            0uff58, 0uff59, 0uff5a, 0uffe0,\
            0uffe1, 0uffe2, 0uffe4, 0uffe5,\
            0uffe6,\
            0u203c, 0u2047, 0u2048, 0u2049] # 濁点、半濁点, Solidus、Reverse solidus, ！-￦, ‼⁇⁈⁉
    vert += j
    j = 0
    while (j < SizeOf(hori))
        if (hori[j] != 0u309b && hori[j] != 0u309c) # ゛゜
            Select(hori[j]); Copy()
            Select(vert + j); Paste()
            if (hori[j] == 0u309b\
             || hori[j] == 0u309c) # ゛゜
                Move(594, -545)
            elseif (hori[j] == 0uff0f\
                 || hori[j] == 0uff3c) # ／＼
                Rotate(-90, 512, 315)
                Move(${move_x_vert_solidus}, 0)
                VFlip()
                CorrectDirection()
            elseif (hori[j] == 0uffe4) # ￤
                Move(0, ${move_y_vert_bbar})
            elseif (hori[j] == 0uff46\
                  || hori[j] == 0uff4c) # ｆｌ
                Move(0, ${move_y_vert_1})
            elseif (hori[j] == 0uff42\
                  || hori[j] == 0uff44\
                  || hori[j] == 0uff48\
                  || hori[j] == 0uff4b) # ｂｄｈｋ
                Move(0, ${move_y_vert_2})
            elseif (hori[j] == 0uff49\
                  || hori[j] == 0uff54) # ｉｔ
                Move(0, ${move_y_vert_3})
            elseif (hori[j] == 0uff41\
                  || hori[j] == 0uff43\
                  || hori[j] == 0uff45\
                  || hori[j] == 0uff4d\
                  || hori[j] == 0uff4e\
                  || hori[j] == 0uff4f\
                  || hori[j] == 0uff52\
                  || hori[j] == 0uff53\
                  || hori[j] == 0uff55\
                  || hori[j] == 0uff56\
                  || hori[j] == 0uff57\
                  || hori[j] == 0uff58\
                  || hori[j] == 0uff5a\
                  || hori[j] == 0uffe0) # ａｃｅｍｎｏｒｓｕｖｗｘｚ￠
                Move(0, ${move_y_vert_4})
            elseif (hori[j] == 0uff4a) # ｊ
                Move(0, ${move_y_vert_5})
            elseif (hori[j] == 0uff50\
                  || hori[j] == 0uff51\
                  || hori[j] == 0uff59) # ｐｑｙ
                Move(0, ${move_y_vert_6})
            elseif (hori[j] == 0uff47) # ｇ
                Move(0, ${move_y_vert_7})
            endif
            Copy(); Select(${address_store_vert} + k); Paste(); SetWidth(${width_zenkaku}) # 保管所にコピー
            Select(${address_store_underline} + 2);  Copy() # 縦線追加
            Select(vert + j); PasteInto()
            SetWidth(${width_zenkaku})
        endif
        j += 1
        k += 1
    endloop

 #    vert += j
 #    Select(0u2702); Copy() # ✂
 #    Select(vert); Paste()
 #    Rotate(-90, 512, 315)
 #    Move(-16, 0)
 #    SetWidth(${width_zenkaku})
 #    j = 1

 #    hori = [0u2016, 0u3030, 0u30a0] # ‖〰゠
 #    vert += j
 #    j = 0
 #    while (j < SizeOf(hori))
 #        Select(hori[j]); Copy()
 #        Select(vert + j); Paste()
 #        if (j == 0) # ‖
 #            Rotate(-90, 512, 315)
 #            Move(-21, -256)
 #            SetWidth(${width_zenkaku})
 #        else # 〰゠
 #            Rotate(-90, 512, 315)
 #            SetWidth(${width_zenkaku})
 #        endif
 #        j += 1
 #    endloop

# 横書き全角形に下線追加
    j = 0 # ！ - ｠
    while (j < 96)
        l = 0uff01 + j
        if (l != 0uff0c && l != 0uff0e\
         && l != 0uff08 && l != 0uff09\
         && l != 0uff5b && l != 0uff5d\
         && l != 0uff3b && l != 0uff3d\
         && l != 0uff5f && l != 0uff60\
         && l != 0uff3f\
         && l != 0uff5e) # ，． （） ｛｝ ［］ ｟｠ ＿ ～
            Select(l)
            Copy(); Select(${address_store_vert} + k); Paste(); SetWidth(${width_zenkaku}) # 保管所にコピー
            Select(${address_store_underline}); Copy() # 下線追加
            Select(l); PasteInto()
            SetWidth(${width_zenkaku})
        endif
        j += 1
        k += 1
    endloop

# 保管しているDQVZに下線追加
    j = 0
    while (j < ${num_mod_glyphs})
        Select(${address_store_mod} + j) # 下線無し時の半角
        SetWidth(${width_hankaku})
        Copy()
        Select(${address_store_mod} + ${num_mod_glyphs} * 3 + j); Paste() # 下線付き時の半角
        SetWidth(${width_hankaku})
        Select(${address_store_mod} + ${num_mod_glyphs} + j); Paste() # 下線無し全角横書き
        Move(256 - ${move_x_hankaku}, 0)
        SetWidth(${width_zenkaku})
        Copy()
        Select(${address_store_mod} + ${num_mod_glyphs} * 2 + j); Paste() # 下線無し全角縦書き
        SetWidth(${width_zenkaku})
        Select(${address_store_mod} + ${num_mod_glyphs} * 4 + j); Paste() # 下線付き全角横書き
        Select(${address_store_mod} + ${num_mod_glyphs} * 5 + j); Paste() # 下線付き全角縦書き
        Select(${address_store_underline}); Copy() # 下線追加
        Select(${address_store_mod} + ${num_mod_glyphs} * 4 + j); PasteInto()
        SetWidth(${width_zenkaku})
        Select(${address_store_underline} + 2); Copy() # 縦線追加
        Select(${address_store_mod} + ${num_mod_glyphs} * 5 + j); PasteInto()
        SetWidth(${width_zenkaku})
        j += 1
    endloop

# 保管しているスラッシュ無し0に下線追加
    Select(${address_store_zero}); Copy() # 下線無し時の半角
    Select(${address_store_zero} + 3); Paste() # 下線無し全角
    Move(256 - ${move_x_hankaku}, 0)
    SetWidth(${width_zenkaku})
    Copy()
    Select(${address_store_zero} + 4); Paste() # 下線付き全角横書き
    Select(${address_store_zero} + 5); Paste() # 下線付き全角縦書き
    Select(${address_store_underline}); Copy() # 下線追加
    Select(${address_store_zero} + 4); PasteInto() # 下線付き全角横書き
    SetWidth(${width_zenkaku})
    Select(${address_store_underline} + 2); Copy() # 縦線追加
    Select(${address_store_zero} + 5); PasteInto() # 下線付き全角縦書き
    SetWidth(${width_zenkaku})

# 半角文字に下線を追加 (ベースフォントのグリフを使うため、カウンターのみ進める)
    Print("Edit hankaku")
    j = 0
    while (j < 63)
 #       Select(0uff61 + j) # ｡-ﾟ
 #       Copy(); Select(${address_store_vert} + k); Paste(); SetWidth(${width_hankaku}) # 保管所にコピー
 #       Select(${address_store_underline} + 1); Copy() # 下線追加
 #       Select(0uff61 + j); PasteInto() # ｡-ﾟ
 #       SetWidth(${width_hankaku})
        j += 1
        k += 1
    endloop

# 横書き全角形に下線追加 (続き)
    Print("Edit zenkaku")
    j = 0 # ￠ - ￦
    while (j < 7)
        l = 0uffe0 + j
        if (l != 0uffe3) # ￣
            Select(l)
            Copy(); Select(${address_store_vert} + k); Paste(); SetWidth(${width_zenkaku}) # 保管所にコピー
            Select(${address_store_underline}); Copy() # 下線追加
            Select(l); PasteInto()
            SetWidth(${width_zenkaku})
        endif
        j += 1
        k += 1
    endloop

    hori = [0u309b, 0u309c, 0u203c, 0u2047,\
            0u2048, 0u2049] # ゛゜‼⁇ ⁈⁉
    j = 0
    while (j < SizeOf(hori))
        if (hori[j] != 0u309b && hori[j] != 0u309c) # ゛゜
            Select(hori[j])
            Copy(); Select(${address_store_vert} + k); Paste(); SetWidth(${width_zenkaku}) # 保管所にコピー
            Select(${address_store_underline});  Copy() # 下線追加
            Select(hori[j]); PasteInto()
            SetWidth(${width_zenkaku})
        endif
        j += 1
        k += 1
    endloop

# 保管している、改変されたグリフの縦書きを追加
    Select(${address_store_visi_latin} + 1); Copy() # |
    Select(${address_store_vert} + 10); Paste() # 縦書き
    Move(256 - ${move_x_hankaku}, 0)
    Rotate(-90, 512, 315)
    Move(${move_x_vert_bar}, 0)
    SetWidth(${width_zenkaku})

 #    Select(${address_store_vert} + 200); Paste() # 全角縦棒を破線にする場合有効にする
 #    Move(256 - ${move_x_hankaku}, 0) # ただし ss06 に対応する処理の追加が必要
 #    SetWidth(${width_zenkaku})

 #    Select(${address_store_visi_kana}); Copy() # ゠
 #    Select(${address_store_vert} + k); Paste() # 縦書き
 #    Rotate(-90, 512, 315)
 #    SetWidth(${width_zenkaku})
 #    k += 1

# あいまい文字等を半角に変換 (ss12のグリフと同じにすること)
    if ("${term_flag}" == "true")
        Print("Set neutral and ambiguous characters to hankaku")

        Select(0u2014) # —
        SelectMore(${address_store_visi_kana} + 4) # 保管所
        Scale(${scale_zenkaku2hankaku} * ${width_hankaku} / ${width_hankaku_loose}, 100, ${width_zenkaku} / 2, 0)
        Move(-(${width_zenkaku} / 2 - ${width_hankaku} / 2), 0)
        Copy()
        Move(-6 * ${width_hankaku_loose} / ${width_hankaku}, 0)
        PasteWithOffset(6 * ${width_hankaku_loose} / ${width_hankaku}, 0)
        OverlapIntersect()
        SetWidth(${width_hankaku})

        Select(0u0021); Copy() # !
        Select(0u203c); Paste() # ‼
        Move(-150 * ${width_hankaku_loose} / ${width_hankaku}, 0)
        Select(0u2049); Paste() # ⁉
        Move(-150 * ${width_hankaku_loose} / ${width_hankaku}, 0)

        Select(0u003f); Copy() # ?
        Select(0u2047); Paste() # ⁇
        Move(-150 * ${width_hankaku_loose} / ${width_hankaku}, 0)
        Select(0u2048); Paste() # ⁈
        Move(-150 * ${width_hankaku_loose} / ${width_hankaku}, 0)

        Select(0u0021); Copy() # !
        Select(0u203c); PasteWithOffset(150 * ${width_hankaku_loose} / ${width_hankaku}, 0) # ‼
        Scale(${scale_zenkaku2hankaku}, 100, ${width_hankaku} / 2, 0)
        SetWidth(${width_hankaku})
        Select(0u2048); PasteWithOffset(150 * ${width_hankaku_loose} / ${width_hankaku}, 0) # ⁈
        Scale(${scale_zenkaku2hankaku}, 100, ${width_hankaku} / 2, 0)
        SetWidth(${width_hankaku})

        Select(0u003f); Copy() # ?
        Select(0u2047); PasteWithOffset(150 * ${width_hankaku_loose} / ${width_hankaku}, 0) # ⁇
        Scale(${scale_zenkaku2hankaku}, 100, ${width_hankaku} / 2, 0)
        SetWidth(${width_hankaku})
        Select(0u2049); PasteWithOffset(150 * ${width_hankaku_loose} / ${width_hankaku}, 0) # ⁉
        Scale(${scale_zenkaku2hankaku}, 100, ${width_hankaku} / 2, 0)
        SetWidth(${width_hankaku})

        Select(0u2025) # ‥
        SelectMore(0u2026) # …
        SelectMore(0u22ef) # ⋯
        foreach
            if (WorthOutputting())
                if (600 <= GlyphInfo("Width"))
                    Scale(${scale_zenkaku2hankaku} * ${width_hankaku} / ${width_hankaku_loose}, 100, ${width_zenkaku} / 2, 0)
                    Move(-(${width_zenkaku} / 2 - ${width_hankaku} / 2), 0)
                    Copy()
                    PasteWithOffset(-10 * ${width_hankaku_loose} / ${width_hankaku}, 0)
                    PasteWithOffset( 10 * ${width_hankaku_loose} / ${width_hankaku}, 0)
                    RemoveOverlap()
                    SetWidth(${width_hankaku})
                endif
            endif
        endloop

        Select(0u2042) # ⁂
        SelectMore(0u2103) # ℃
        SelectMore(0u2109) # ℉
        SelectMore(0u2669, 0u266a) # ♩♪
        SelectMore(0u266b) # ♫
        SelectMore(0u266c, 0u266d) # ♬♭
        SelectMore(0u266e) # ♮
        SelectMore(0u266f) # ♯
        foreach
            if (WorthOutputting())
                if (600 <= GlyphInfo("Width"))
                    Scale(${scale_zenkaku2hankaku} * ${width_hankaku} / ${width_hankaku_loose} * 1.2, 100, ${width_zenkaku} / 2, 0)
                    Move(-(${width_zenkaku} / 2 - ${width_hankaku} / 2), 0)
                    SetWidth(${width_hankaku})
                endif
            endif
        endloop

        Select(0u2051) # ⁑
        SelectMore(0u22ee) # ⋮
        SelectMore(0u2307) # ⌇
        foreach
            if (WorthOutputting())
                if (600 <= GlyphInfo("Width"))
                    Move(-(${width_zenkaku} / 2 - ${width_hankaku} / 2), 0)
                    SetWidth(${width_hankaku})
                endif
            endif
        endloop

        Select(0u2460, 0u2487) # ①-⒇
        SelectMore(0u249c, 0u24e9) # ⒜-ⓩ
        SelectMore(0u24ea) # ⓪
        SelectMore(0u24eb, 0u24ff) # ⓫-⓿
        SelectMore(0u2776, 0u277f) # ❶-❿
        SelectMore(0u2780, 0u2793) # ➀-➓
        SelectMore(${address_store_visi_kana} + 6, ${address_store_visi_kana} + 25) # 保管所
        foreach
            if (WorthOutputting())
                if (600 <= GlyphInfo("Width"))
                    Scale(${scale_zenkaku2hankaku} * ${width_hankaku} / ${width_hankaku_loose} * 0.95, 100, ${width_zenkaku} / 2, 0)
                    Move(-(${width_zenkaku} / 2 - ${width_hankaku} / 2), 0)
                    SetWidth(${width_hankaku})
                endif
            endif
        endloop

        Select(0u2660, 0u2661) # ♠♡
        SelectMore(0u2662) # ♢
        SelectMore(0u2663, 0u2665) # ♣♤♥
        SelectMore(0u2666) # ♦
        SelectMore(0u2667) # ♧
        foreach
            if (WorthOutputting())
                if (600 <= GlyphInfo("Width"))
                    Scale(${scale_zenkaku2hankaku} * ${width_hankaku} / ${width_hankaku_loose} * 1.1, 100, ${width_zenkaku} / 2, 0)
                    Move(-(${width_zenkaku} / 2 - ${width_hankaku} / 2), 0)
                    SetWidth(${width_hankaku})
                endif
            endif
        endloop

        Select(0u25e2) # ◢
        SelectMore(0u25e5) # ◥
        foreach
            if (WorthOutputting())
                if (600 <= GlyphInfo("Width"))
                    Scale(${scale_zenkaku2hankaku} * ${width_hankaku} / ${width_hankaku_loose}, 100, ${width_zenkaku}, 0)
                    Move(-(${width_zenkaku} - ${width_hankaku}), 0)
                    SetWidth(${width_hankaku})
                endif
            endif
        endloop

        Select(0u25e3) # ◣
        SelectMore(0u25e4) # ◤
        foreach
            if (WorthOutputting())
                if (600 <= GlyphInfo("Width"))
                    Scale(${scale_zenkaku2hankaku} * ${width_hankaku} / ${width_hankaku_loose}, 100, 0, 0)
                    SetWidth(${width_hankaku})
                endif
            endif
        endloop

        Select(0u00bc, 0u00be) # ¼½¾

        SelectMore(0u2000, 0u200a) # スペース
        SelectMore(0u200b, 0u200f) # スペース
        SelectMore(0u2010) # ‐
        SelectMore(0u2011, 0u2012) # ‑‒
        SelectMore(0u2013, 0u2015) # –—―
        SelectMore(0u2016) # ‖
        SelectMore(0u2017) # ‗
        SelectMore(0u2018) # ‘
        SelectMore(0u2019) # ’
        SelectMore(0u201a) # ‚
        SelectMore(0u201b) # ‛
        SelectMore(0u201c) # “
        SelectMore(0u201d) # ”
        SelectMore(0u201e) # „
        SelectMore(0u201f) # ‟
        SelectMore(0u2020, 0u2022) # †‡•
        SelectMore(0u2023) # ‣
        SelectMore(0u2024) # ․
        SelectMore(0u2027) # ‧
        SelectMore(0u202f) # narrow no-break space
        SelectMore(0u2030) # ‰
        SelectMore(0u2031) # ‱
        SelectMore(0u2032, 0u2033) # ′″
        SelectMore(0u2034) # ‴
        SelectMore(0u2035) # ‵
        SelectMore(0u2036, 0u2038) # ‶‷‸
        SelectMore(0u2039) # ‹
        SelectMore(0u203a) # ›
        SelectMore(0u203b) # ※
        SelectMore(0u203d) # ‽
        SelectMore(0u203e) # ‾
        SelectMore(0u203f, 0u2040) # ‿⁀
        SelectMore(0u2041) # ⁁
        SelectMore(0u2043) # ⁃
        SelectMore(0u2044) # ⁄
        SelectMore(0u2045) # ⁅
        SelectMore(0u2046) # ⁆
        SelectMore(0u2050) # ⁐
        SelectMore(0u2052) # ⁒
        SelectMore(0u2053) # ⁓
        SelectMore(0u2054) # ⁔
        SelectMore(0u2055, 0u205e) # ⁕
        SelectMore(0u205f) # medium mathematical space
        SelectMore(0u20a0, 0u20a8) # ₠-₨
        SelectMore(0u20aa, 0u20ab) # ₪₫
        SelectMore(0u20ac) # €
        SelectMore(0u20ad, 0u20c0) # ₭-⃀

        SelectMore(0u2100, 0u2101) # ℀℁
        SelectMore(0u2102) # ℂ
        SelectMore(0u2104) # ℄
        SelectMore(0u2105) # ℅
        SelectMore(0u2106) # ℆
        SelectMore(0u2107) # ℇ
        SelectMore(0u2108) # ℈
        SelectMore(0u210a, 0u2112) # ℊ-ℒ
        SelectMore(0u2113) # ℓ
        SelectMore(0u2114) # ℔
        SelectMore(0u2115) # ℕ
        SelectMore(0u2116) # №
        SelectMore(0u2117) # ℗
        SelectMore(0u2118) # ℘
        SelectMore(0u2119, 0u211d) # ℙ-ℝ
        SelectMore(0u211e, 0u2120) # ℞-℠
        SelectMore(0u2121, 0u2122) # ℡-™
        SelectMore(0u2123) # ℣
        SelectMore(0u2124) # ℤ
        SelectMore(0u2125) # ℥
        SelectMore(0u2126) # Ω
        SelectMore(0u2127) # ℧
        SelectMore(0u2128) # ℨ
        SelectMore(0u2129) # ℩
        SelectMore(0u212a) # K
        SelectMore(0u212b) # Å
        SelectMore(0u212c, 0u212d) # ℬℭ
        SelectMore(0u212e) # ℮
        SelectMore(0u212f, 0u2134) # ℯ
        SelectMore(0u2135, 0u2138) # ℵ-ℸ
        SelectMore(0u2139) # ℹ
        SelectMore(0u213a, 0u213b) # ℺℻
        SelectMore(0u213c, 0u213f) # ℼℿ
        SelectMore(0u2140, 0u2144) # ⅀-⅄
        SelectMore(0u2145, 0u2149) # ⅅ-ⅉ
        SelectMore(0u214a) # ⅊
        SelectMore(0u214b) # ⅋
        SelectMore(0u214c, 0u214d) # ⅌⅍
        SelectMore(0u214e) # ⅎ
        SelectMore(0u214f) # ⅏
        SelectMore(0u2150, 0u2152) # ⅐⅑⅒
        SelectMore(0u2153, 0u2154) # ⅓⅔
        SelectMore(0u2155, 0u215a) # ⅕-⅚
        SelectMore(0u215b, 0u215e) # ⅛-⅞
        SelectMore(0u215f) # ⅟
        SelectMore(0u2160, 0u216b) # Ⅰ-Ⅻ
        SelectMore(0u216c, 0u216f) # Ⅼ-Ⅿ
        SelectMore(0u2170, 0u2179) # ⅰ-ⅹ
        SelectMore(0u217a, 0u2182) # ⅺ-ↂ
        SelectMore(0u2183, 0u2184) # Ↄↄ
        SelectMore(0u2185, 0u2188) # ↅ-ↈ
        SelectMore(0u2189) # ↉
        SelectMore(0u218a, 0u218b) # ↊↋

        SelectMore(0u2200) # ∀
        SelectMore(0u2201) # ∁
        SelectMore(0u2202, 0u2203) # ∂∃
        SelectMore(0u2204, 0u2206) # ∄∅∆
        SelectMore(0u2207, 0u2208) # ∇∈
        SelectMore(0u2209, 0u220a) # ∉∊
        SelectMore(0u220b) # ∋
        SelectMore(0u220c, 0u220e) # ∌∍∎
        SelectMore(0u220f) # ∏
        SelectMore(0u2210) # ∐
        SelectMore(0u2211) # ∑
        SelectMore(0u2212, 0u2214) # −∓∔
        SelectMore(0u2215) # ∕
        SelectMore(0u2216, 0u2219) # ∖-∙
        SelectMore(0u221a) # √
        SelectMore(0u221b, 0u221c) # ∛∜
        SelectMore(0u221d, 0u221e) # ∝∞
        SelectMore(0u2223) # ∣
        SelectMore(0u2224) # ∤
        SelectMore(0u2225) # ∥
        SelectMore(0u2226) # ∦
        SelectMore(0u2227, 0u222c) # ∧-∬
        SelectMore(0u222d) # ∭
        SelectMore(0u222e) # ∮
        SelectMore(0u222f, 0u2233) # ∯-∳
        SelectMore(0u2234, 0u2237) # ∴-∷
        SelectMore(0u2238, 0u223b) # ∸-∻
        SelectMore(0u223c, 0u223d) # ∼∽
        SelectMore(0u223e, 0u2247) # ∾-≇
        SelectMore(0u2248) # ≈
        SelectMore(0u2249, 0u224b) # ≉≊≋
        SelectMore(0u224c) # ≌
        SelectMore(0u224d, 0u2251) # ≍-≑
        SelectMore(0u2252) # ≒
        SelectMore(0u2253, 0u225f) # ≓-≟
        SelectMore(0u2260, 0u2261) # ≠≡
        SelectMore(0u2262, 0u2263) # ≢≣
        SelectMore(0u2264, 0u2267) # ≤≧
        SelectMore(0u2268, 0u2269) # ≨≩
        SelectMore(0u226a, 0u226b) # ≪≫
        SelectMore(0u226c, 0u226d) # ≬≭
        SelectMore(0u226e, 0u226f) # ≮≯
        SelectMore(0u2270, 0u2281) # ≰-⊁
        SelectMore(0u2282, 0u2283) # ⊂⊃
        SelectMore(0u2284, 0u2285) # ⊄⊅
        SelectMore(0u2286, 0u2287) # ⊆⊇
        SelectMore(0u2288, 0u2294) # ⊈-⊔
        SelectMore(0u22c0, 0u22ed) # ⋀-⋭
        SelectMore(0u22f0, 0u22ff) # ⋰-⋿

        SelectMore(0u2301) # ⌁
        SelectMore(0u2308) # ⌈
        SelectMore(0u2309) # ⌉
        SelectMore(0u230a) # ⌊
        SelectMore(0u230b) # ⌋
        SelectMore(0u230c, 0u2311) # ⌌-⌑
        SelectMore(0u2319) # ⌙
        SelectMore(0u231c, 0u231f) # ⌜-⌟
        SelectMore(0u2320, 0u2321) # ⌠⌡
        SelectMore(0u237c) # ⍼
        SelectMore(0u239b, 0u23b3) # ⎛-⎳
        SelectMore(0u23b4, 0u23bd) # ⎴-⎽
        SelectMore(0u23d0, 0u23db) # ⏐-⏛
        SelectMore(0u23dc, 0u23e1) # ⏜-⏡

        SelectMore(0u2400, 0u2426) # ␀-␦
        SelectMore(0u2440, 0u244a) # ⑀-⑊
        SelectMore(0u2488, 0u249b) # ⒈-⒛

        SelectMore(0u2500, 0u254b) # ─-╋
        SelectMore(0u254c, 0u254f) # ╌╎╏
        SelectMore(0u2550, 0u2573) # ═-╳
        SelectMore(0u2574, 0u257f) # ╴-╿
        SelectMore(0u2580, 0u258f) # ▀-▏
        SelectMore(0u2590, 0u2591) # ▐░
        SelectMore(0u2592, 0u2595) # ▒▕
        SelectMore(0u2596, 0u259f) # ▖-▟

        SelectMore(0u260e, 0u260f) # ☎☏
        SelectMore(0u2613) # ☓
        SelectMore(0u2616, 0u2617) # ☖☗
        SelectMore(0u2620) # ☠
        SelectMore(0u2630, 0u2637) # ☰-☷
        SelectMore(0u2668) # ♨
        SelectMore(0u2672, 0u267b) # ♲-♻
        SelectMore(0u268a, 0u268f) # ⚌-⚏
        SelectMore(0u2690, 0u2691) # ⚐⚑
        SelectMore(0u26a0) # ⚠
        SelectMore(0u26c9, 0u26ca) # ⛉⛊

        SelectMore(0u2756) # ❖
        SelectMore(0u2758, 0u2763) # ❘-❣
        SelectMore(0u2768) # ❨
        SelectMore(0u2769) # ❩
        SelectMore(0u276a) # ❪
        SelectMore(0u276b) # ❫
        SelectMore(0u276c) # ❬
        SelectMore(0u276d) # ❭
        SelectMore(0u276e) # ❮
        SelectMore(0u276f) # ❯
        SelectMore(0u2770) # ❰
        SelectMore(0u2771) # ❱
        SelectMore(0u2772) # ❲
        SelectMore(0u2773) # ❳
        SelectMore(0u2774) # ❴
        SelectMore(0u2775) # ❵
        SelectMore(0u27c0, 0u27c4) # ⟀-⟄
        SelectMore(0u27c5) # ⟅
        SelectMore(0u27c6) # ⟆
        SelectMore(0u27c7, 0u27e5) # ⟇-⟥
        SelectMore(0u27ee) # ⟮
        SelectMore(0u27ef) # ⟯

        SelectMore(0u2800, 0u28ff) # ⠀-⣿

        SelectMore(0u2980, 0u2982) # ⦀⦁⦂
        SelectMore(0u2983) # ⦃
        SelectMore(0u2984) # ⦄
        SelectMore(0u2987) # ⦇
        SelectMore(0u2988) # ⦈
        SelectMore(0u2989) # ⦉
        SelectMore(0u298a) # ⦊
        SelectMore(0u298b) # ⦋
        SelectMore(0u298c) # ⦌
        SelectMore(0u298d) # ⦍
        SelectMore(0u298e) # ⦎
        SelectMore(0u298f) # ⦏
        SelectMore(0u2990) # ⦐
        SelectMore(0u2991) # ⦑
        SelectMore(0u2992) # ⦒
        SelectMore(0u2993) # ⦓
        SelectMore(0u2994) # ⦔
        SelectMore(0u2995) # ⦕
        SelectMore(0u2996) # ⦖
        SelectMore(0u2997) # ⦗
        SelectMore(0u2998) # ⦘
        SelectMore(0u2999, 0u29d7) # ⦙-⧗
        SelectMore(0u29d8) # ⧘
        SelectMore(0u29d9) # ⧙
        SelectMore(0u29da) # ⧚
        SelectMore(0u29db) # ⧛
        SelectMore(0u29dc, 0u29fb) # ⧜-⧻
        SelectMore(0u29fc) # ⧼
        SelectMore(0u29fd) # ⧽
        SelectMore(0u29fe, 0u29ff) # ⧾⧿

        SelectMore(0u2a00, 0u2aff) # ⨀-⫿

        SelectMore(0u1f100) # 🄀

        foreach
            if (WorthOutputting())
                if (600 <= GlyphInfo("Width"))
                    Scale(${scale_zenkaku2hankaku} * ${width_hankaku} / ${width_hankaku_loose}, 100, ${width_zenkaku} / 2, 0)
                    Move(-(${width_zenkaku} / 2 - ${width_hankaku} / 2), 0)
                    SetWidth(${width_hankaku})
                endif
            endif
        endloop

        Select(0u2190, 0u2194) # ←-↔
        SelectMore(0u2195, 0u2199) # ↕-↙
        SelectMore(0u219a, 0u219b) # ↚↛
        SelectMore(0u219c, 0u219f) # ↜-↟
        SelectMore(0u21a0) # ↠
        SelectMore(0u21a1, 0u21a2) # ↡↢
        SelectMore(0u21a3) # ↣
        SelectMore(0u21a4, 0u21a5) # ↤↥
        SelectMore(0u21a6) # ↦
        SelectMore(0u21a7, 0u21ad) # ↧-↭
        SelectMore(0u21ae) # ↮
        SelectMore(0u21af, 0u21b7) # ↯-↷
        SelectMore(0u21b8) # ↸
        SelectMore(0u21b9) # ↹
        SelectMore(0u21ba, 0u21cd) # ↺-⇍
        SelectMore(0u21ce, 0u21cf) # ⇎⇏
        SelectMore(0u21d0, 0u21d1) # ⇐⇑
        SelectMore(0u21d2) # ⇒
        SelectMore(0u21d3) # ⇓
        SelectMore(0u21d4) # ⇔
        SelectMore(0u21d5, 0u21e6) # ⇕-⇦
        SelectMore(0u21e7) # ⇧
        SelectMore(0u21e8, 0u21f3) # ⇨
        SelectMore(0u21f4, 0u21ff) # ⇴

        SelectMore(0u221f, 0u2220) # ∟∠
        SelectMore(0u2221, 0u2222) # ∡∢
        SelectMore(0u2295) # ⊕
        SelectMore(0u2296, 0u2298) # ⊖⊗⊘
        SelectMore(0u2299) # ⊙
        SelectMore(0u229a, 0u22a4) # ⊚-⊤
        SelectMore(0u22a5) # ⊥
        SelectMore(0u22a6, 0u22be) # ⊦-⊾
        SelectMore(0u22bf) # ⊿
        SelectMore(0u2300) # ⌀
        SelectMore(0u2302) # ⌂
        SelectMore(0u2303, 0u2306) # ⌃-⌆
        SelectMore(0u2312) # ⌒
        SelectMore(0u2313, 0u2318) # ⌓-⌘
        SelectMore(0u2322, 0u2328) # ⌢-⌨
        SelectMore(0u232b, 0u237b) # ⌫-⍻
        SelectMore(0u237d, 0u239a) # ⍽-⎚
        SelectMore(0u23be, 0u23cc) # ⎾-⏌
        SelectMore(0u23cd, 0u23cf) # ⏍⏎⏏
        SelectMore(0u23e2, 0u23e8) # ⏢-⏨
        SelectMore(0u23ed, 0u23ef) # ⏭⏯
        SelectMore(0u23f1, 0u23f2) # ⏱⏲
        SelectMore(0u23f4, 0u23ff) # ⏴-⏿

        SelectMore(0u25a0, 0u25a1) # ■□
        SelectMore(0u25a2) # ▢
        SelectMore(0u25a3, 0u25a9) # ▣-▩
        SelectMore(0u25aa, 0u25b1) # ▪-▱
        SelectMore(0u25b2, 0u25b3) # ▲△
        SelectMore(0u25b4, 0u25b5) # ▴▵
        SelectMore(0u25b6) # ▶
        SelectMore(0u25b7) # ▷
        SelectMore(0u25b8, 0u25bb) # ▸-▻
        SelectMore(0u25bc, 0u25bd) # ▼▽
        SelectMore(0u25be, 0u25bf) # ▾▿
        SelectMore(0u25c0) # ◀
        SelectMore(0u25c1) # ◁
        SelectMore(0u25c2, 0u25c5) # ◂-◅
        SelectMore(0u25c6, 0u25c8) # ◆◇◈
        SelectMore(0u25c9, 0u25ca) # ◉◊
        SelectMore(0u25cb) # ○
        SelectMore(0u25cc, 0u25cd) # ◌◍
        SelectMore(0u25ce, 0u25d1) # ◎-◑
        SelectMore(0u25d2, 0u25e1) # ◒-◡
        SelectMore(0u25e6, 0u25ee) # ◦-◮
        SelectMore(0u25ef) # ◯
        SelectMore(0u25f0, 0u25f7) # ◰-◷
        SelectMore(0u25f8, 0u25fc) # ◸-◼
        SelectMore(0u25ff) # ◿

        SelectMore(0u2600, 0u2604) # ☀-☄
        SelectMore(0u2605, 0u2606) # ★☆
        SelectMore(0u2607, 0u2608) # ☇☈
        SelectMore(0u2609) # ☉
        SelectMore(0u260a, 0u260d) # ☊-☍
        SelectMore(0u2610, 0u2612) # ☐☑☒
        SelectMore(0u2618, 0u2619) # ☘☙
        SelectMore(0u261a, 0u261b) # ☚☛
        SelectMore(0u261c) # ☜
        SelectMore(0u261d) # ☝
        SelectMore(0u261e) # ☞
        SelectMore(0u261f) # ☟
        SelectMore(0u2621, 0u262f) # ☡-☯
        SelectMore(0u2638, 0u263b) # ☸-☻
        SelectMore(0u263c) # ☼
        SelectMore(0u263d, 0u263f) # ☽☾☿
        SelectMore(0u2640) # ♀
        SelectMore(0u2641) # ♁
        SelectMore(0u2642) # ♂
        SelectMore(0u2643, 0u2647) # ♃-♇
        SelectMore(0u2654, 0u265f) # ♔-♟
        SelectMore(0u2670, 0u2671) # ♰♱
        SelectMore(0u267c, 0u267e) # ♼♽♾
        SelectMore(0u2680, 0u2689) # ⚀-⚉
        SelectMore(0u2692) # ⚒
        SelectMore(0u2694, 0u269d) # ⚔-⚝
        SelectMore(0u269e, 0u269f) # ⚞⚟
        SelectMore(0u26a2, 0u26a9) # ⚢-⚩
        SelectMore(0u26ac, 0u26bc) # ⚬-⚼
        SelectMore(0u26bf) # ⚿
        SelectMore(0u26c0, 0u26c3) # ⛀-⛃
        SelectMore(0u26c6, 0u26c8) # ⛆⛇⛈
        SelectMore(0u26cb, 0u26cd) # ⛋-⛍
        SelectMore(0u26cf, 0u26d3) # ⛏-⛓
        SelectMore(0u26d5, 0u26e1) # ⛕-⛡
        SelectMore(0u26e2) # ⛢
        SelectMore(0u26e3) # ⛣
        SelectMore(0u26e4, 0u26e7) # ⛤-⛧
        SelectMore(0u26e8, 0u26e9) # ⛨⛩
        SelectMore(0u26eb, 0u26f1) # ⛫-⛱
        SelectMore(0u26f4) # ⛴
        SelectMore(0u26f6, 0u26f9) # ⛶-⛹
        SelectMore(0u26fb, 0u26fc) # ⛻-⛼
        SelectMore(0u26fe, 0u26ff) # ⛾⛿

        SelectMore(0u2700, 0u2704) # ✀-✄
        SelectMore(0u2708, 0u2709) # ✈✉
        SelectMore(0u2706, 0u2707) # ✆✇
        SelectMore(0u270c, 0u2727) # ✌-✧
        SelectMore(0u2729, 0u273c) # ✩-✼
        SelectMore(0u273d) # ✽
        SelectMore(0u273e, 0u274b) # ✾-❋
        SelectMore(0u274d) # ❍
        SelectMore(0u274f, 0u2752) # ❏-❒
        SelectMore(0u2764, 0u2767) # ❤-❧
        SelectMore(0u2794) # ➔
        SelectMore(0u2798, 0u27af) # ➘-➯
        SelectMore(0u27b1, 0u27be) # ➱-➾
        SelectMore(0u27f0, 0u27ff) # ⟰-⟿

        SelectMore(0u2900, 0u297f) # ⤀-⥿
        SelectMore(0u2b00, 0u2b1a) # ⬀-⬚
        SelectMore(0u2b1d, 0u2b2f) # ⬝-⬯
        SelectMore(0u2b30, 0u2b44) # ⬰-⭄
        SelectMore(0u2b45, 0u2b46) # ⭅⭆
        SelectMore(0u2b47, 0u2b4c) # ⭇-⭌
        SelectMore(0u2b4d, 0u2b4f) # ⭍⭎⭏
        SelectMore(0u2b51, 0u2b54) # ⭑-⭔
        SelectMore(0u2b56, 0u2b59) # ⭖-⭙
        SelectMore(0u2b5a, 0u2b73) # ⭚-⭳
        SelectMore(0u2b76, 0u2b95) # ⭶-⮕
        SelectMore(0u2b97, 0u2bff) # ⮗-⯿

        foreach
            if (WorthOutputting())
                if (600 <= GlyphInfo("Width"))
                    Scale(${scale_zenkaku2hankaku} * ${width_hankaku} / ${width_hankaku_loose}, ${width_zenkaku} / 2, 340)
                    Move(-(${width_zenkaku} / 2 - ${width_hankaku} / 2), 0)
                    SetWidth(${width_hankaku})
                endif
            endif
        endloop

    endif

# --------------------------------------------------

# 失われたLookupを追加
    # vert
    Print("Add vert lookups")
    Select(0u3041) # ぁ
    lookups = GetPosSub("*") # フィーチャを取り出す

    # ‼⁇⁈⁉✂‖
    hori = [0u203c, 0u2047, 0u2048, 0u2049, 0u2702, 0u2016]
    vert = ${address_vert_bracket} + 105 # グリフの数によって変更の必要あり
    j = 0
    while (j < SizeOf(hori))
        Select(vert + j)
        glyphName = GlyphInfo("Name")
        Select(hori[j])
        AddPosSub(lookups[0][0], glyphName)
        j += 1
    endloop

# calt 対応 (変更した時はスロットの追加とパッチ側の変更も忘れないこと)
    Print("Add calt lookups")
    lookups = GetLookups("GSUB"); numlookups = SizeOf(lookups)

    # グリフ変換用 lookup
    lookupName = "単純置換 (中・ラテン文字)"
    AddLookup(lookupName, "gsub_single", 0, [], lookups[numlookups - 1]) # lookup の最後に追加
    lookupSub0 = lookupName + "サブテーブル"
    AddLookupSubtable(lookupName, lookupSub0)

    lookupName = "単純置換 (左・ラテン文字)"
    AddLookup(lookupName, "gsub_single", 0, [], lookups[numlookups - 1])
    lookupSub1 = lookupName + "サブテーブル"
    AddLookupSubtable(lookupName, lookupSub1)
    k = ${address_calt_AL}
    j = 0
    while (j < 26)
        Select(0u0041 + j); Copy() # A
        glyphName = GlyphInfo("Name")
        Select(k); Paste()
        Move(-${move_x_calt_latin}, 0)
        SetWidth(${width_hankaku})
        AddPosSub(lookupSub0, glyphName) # 左→中
        glyphName = GlyphInfo("Name")
        Select(0u0041 + j) # A
        AddPosSub(lookupSub1, glyphName) # 左←中
        j += 1
        k += 1
    endloop
    j = 0
    while (j < 26)
        Select(0u0061 + j); Copy() # a
        glyphName = GlyphInfo("Name")
        Select(k); Paste()
        Move(-${move_x_calt_latin}, 0)
        SetWidth(${width_hankaku})
        AddPosSub(lookupSub0, glyphName) # 左→中
        glyphName = GlyphInfo("Name")
        Select(0u0061 + j) # a
        AddPosSub(lookupSub1, glyphName) # 左←中
        j += 1
        k += 1
    endloop

    j = 0
    while (j < 64)
        l = 0u00c0 + j
        if (l != 0u00c6\
         && l != 0u00d7\
         && l != 0u00e6\
         && l != 0u00f7)
            Select(l); Copy() # À
            glyphName = GlyphInfo("Name")
            Select(k); Paste()
            Move(-${move_x_calt_latin}, 0)
            SetWidth(${width_hankaku})
            AddPosSub(lookupSub0, glyphName) # 左→中
            glyphName = GlyphInfo("Name")
            Select(l) # À
            AddPosSub(lookupSub1, glyphName) # 左←中
            k += 1
        endif
        j += 1
    endloop

    j = 0
    while (j < 128)
        l = 0u0100 + j
        if (l != 0u0132\
         && l != 0u0133\
         && l != 0u0149\
         && l != 0u0152\
         && l != 0u0153\
         && l != 0u017f)
            Select(l); Copy() # Ā
            glyphName = GlyphInfo("Name")
            Select(k); Paste()
            Move(-${move_x_calt_latin}, 0)
            SetWidth(${width_hankaku})
            AddPosSub(lookupSub0, glyphName) # 左→中
            glyphName = GlyphInfo("Name")
            Select(l) # Ā
            AddPosSub(lookupSub1, glyphName) # 左←中
            k += 1
        endif
        j += 1
    endloop

    j = 0
    while (j < 4)
        l = 0u0218 + j
        Select(l); Copy() # Ș
        glyphName = GlyphInfo("Name")
        Select(k); Paste()
        Move(-${move_x_calt_latin}, 0)
        SetWidth(${width_hankaku})
        AddPosSub(lookupSub0, glyphName) # 左→中
        glyphName = GlyphInfo("Name")
        Select(l) # Ș
        AddPosSub(lookupSub1, glyphName) # 左←中
        k += 1
        j += 1
    endloop

    Select(0u1e9e); Copy() # ẞ
    glyphName = GlyphInfo("Name")
    Select(k); Paste()
    Move(-${move_x_calt_latin}, 0)
    SetWidth(${width_hankaku})
    AddPosSub(lookupSub0, glyphName) # 左←中
    glyphName = GlyphInfo("Name")
    Select(0u1e9e) # ẞ
    AddPosSub(lookupSub1, glyphName) # 左→中
    k += 1

    lookupName = "単純置換 (右・ラテン文字)"
    AddLookup(lookupName, "gsub_single", 0, [], lookups[numlookups - 1])
    lookupSub1 = lookupName + "サブテーブル"
    AddLookupSubtable(lookupName, lookupSub1)
    j = 0
    while (j < 26)
        Select(0u0041 + j); Copy() # A
        glyphName = GlyphInfo("Name")
        Select(k); Paste()
        Move(${move_x_calt_latin}, 0)
        SetWidth(${width_hankaku})
        AddPosSub(lookupSub0, glyphName) # 中←右
        glyphName = GlyphInfo("Name")
        Select(0u0041 + j) # A
        AddPosSub(lookupSub1, glyphName) # 中→右
        j += 1
        k += 1
    endloop
    j = 0
    while (j < 26)
        Select(0u0061 + j); Copy() # a
        glyphName = GlyphInfo("Name")
        Select(k); Paste()
        Move(${move_x_calt_latin}, 0)
        SetWidth(${width_hankaku})
        AddPosSub(lookupSub0, glyphName) # 中←右
        glyphName = GlyphInfo("Name")
        Select(0u0061 + j) # a
        AddPosSub(lookupSub1, glyphName) # 中→右
        j += 1
        k += 1
    endloop

    j = 0
    while (j < 64)
        l = 0u00c0 + j
        if (l != 0u00c6\
         && l != 0u00d7\
         && l != 0u00e6\
         && l != 0u00f7)
            Select(l); Copy() # À
            glyphName = GlyphInfo("Name")
            Select(k); Paste()
            Move(${move_x_calt_latin}, 0)
            SetWidth(${width_hankaku})
            AddPosSub(lookupSub0, glyphName) # 中←右
            glyphName = GlyphInfo("Name")
            Select(l) # À
            AddPosSub(lookupSub1, glyphName) # 中→右
            k += 1
        endif
        j += 1
    endloop

    j = 0
    while (j < 128)
        l = 0u0100 + j
        if (l != 0u0132\
         && l != 0u0133\
         && l != 0u0149\
         && l != 0u0152\
         && l != 0u0153\
         && l != 0u017f)
            Select(l); Copy() # Ā
            glyphName = GlyphInfo("Name")
            Select(k); Paste()
            Move(${move_x_calt_latin}, 0)
            SetWidth(${width_hankaku})
            AddPosSub(lookupSub0, glyphName) # 中←右
            glyphName = GlyphInfo("Name")
            Select(l) # Ā
            AddPosSub(lookupSub1, glyphName) # 中→右
            k += 1
        endif
        j += 1
    endloop

    j = 0
    while (j < 4)
        l = 0u0218 + j
        Select(l); Copy() # Ș
        glyphName = GlyphInfo("Name")
        Select(k); Paste()
        Move(${move_x_calt_latin}, 0)
        SetWidth(${width_hankaku})
        AddPosSub(lookupSub0, glyphName) # 中←右
        glyphName = GlyphInfo("Name")
        Select(l) # Ș
        AddPosSub(lookupSub1, glyphName) # 中→右
        k += 1
        j += 1
    endloop

    Select(0u1e9e); Copy() # ẞ
    glyphName = GlyphInfo("Name")
    Select(k); Paste()
    Move(${move_x_calt_latin}, 0)
    SetWidth(${width_hankaku})
    AddPosSub(lookupSub0, glyphName) # 中←右
    glyphName = GlyphInfo("Name")
    Select(0u1e9e) # ẞ
    AddPosSub(lookupSub1, glyphName) # 中→右
    k += 1

    lookupName = "単純置換 (3桁)"
    AddLookup(lookupName, "gsub_single", 0, [], lookups[numlookups - 1])
    lookupSub1 = lookupName + "サブテーブル"
    AddLookupSubtable(lookupName, lookupSub1)

    j = 0
    while (j < 10)
        Select(${address_store_b_diagram}); Copy() # 保管した▲
        Select(k); Paste()
        Scale(15, 27)
        Move(${move_x_calt_separate}, ${move_y_calt_separate3})
        Copy(); Select(k + 20); Paste() # 12桁用
        Select(0u0030 + j); Copy() # 0
        glyphName = GlyphInfo("Name")
        Select(k); PasteInto()
        SetWidth(${width_hankaku})
        AddPosSub(lookupSub0, glyphName) # ノーマル←3桁マーク付加
        glyphName = GlyphInfo("Name")
        Select(0u0030 + j) # 0
        AddPosSub(lookupSub1, glyphName) # 3桁マーク付加←ノーマル
 #        Select(k + 10) # 0
 #        AddPosSub(lookupSub1, glyphName) # 3桁マーク付加←4桁マーク付加
        Select(k + 20) # 0
        AddPosSub(lookupSub1, glyphName) # 3桁マーク付加←12桁マーク付加
        k += 1
        j += 1
    endloop

    lookupName = "単純置換 (4桁)"
    AddLookup(lookupName, "gsub_single", 0, [], lookups[numlookups - 1])
    lookupSub1 = lookupName + "サブテーブル"
    AddLookupSubtable(lookupName, lookupSub1)

    j = 0
    while (j < 10)
        Select(${address_store_b_diagram} + 1); Copy() # 保管した▼
        Select(k); Paste()
        Scale(15, 27)
        Move(${move_x_calt_separate}, ${move_y_calt_separate4})
        Copy(); Select(k + 10); PasteInto() # 12桁用
        Select(0u0030 + j); Copy() # 0
        glyphName = GlyphInfo("Name")
        Select(k); PasteInto()
        SetWidth(${width_hankaku})
        AddPosSub(lookupSub0, glyphName) # ノーマル←4桁マーク付加
        glyphName = GlyphInfo("Name")
        Select(0u0030 + j) # 0
        AddPosSub(lookupSub1, glyphName) # 4桁マーク付加←ノーマル
 #        Select(k - 10) # 0
 #        AddPosSub(lookupSub1, glyphName) # 4桁マーク付加←3桁マーク付加
 #        Select(k + 10) # 0
 #        AddPosSub(lookupSub1, glyphName) # 4桁マーク付加←12桁マーク付加
        k += 1
        j += 1
    endloop

    lookupName = "単純置換 (12桁)"
    AddLookup(lookupName, "gsub_single", 0, [], lookups[numlookups - 1])
    lookupSub1 = lookupName + "サブテーブル"
    AddLookupSubtable(lookupName, lookupSub1)

    j = 0
    while (j < 10)
        Select(0u0030 + j); Copy() # 0
        glyphName = GlyphInfo("Name")
        Select(k); PasteInto()
        SetWidth(${width_hankaku})
        AddPosSub(lookupSub0, glyphName) # ノーマル←12桁マーク付加
        glyphName = GlyphInfo("Name")
        Select(0u0030 + j) # 0
        AddPosSub(lookupSub1, glyphName) # 12桁マーク付加←ノーマル
 #        Select(k - 20) # 0
 #        AddPosSub(lookupSub1, glyphName) # 12桁マーク付加←3桁マーク付加
 #        Select(k - 10) # 0
 #        AddPosSub(lookupSub1, glyphName) # 12桁マーク付加←4桁マーク付加
        k += 1
        j += 1
    endloop

    lookupName = "単純置換 (小数)"
    AddLookup(lookupName, "gsub_single", 0, [], lookups[numlookups - 1])
    lookupSub1 = lookupName + "サブテーブル"
    AddLookupSubtable(lookupName, lookupSub1)

    j = 0
    while (j < 10)
        Select(0u0030 + j); Copy() # 0
        glyphName = GlyphInfo("Name")
        Select(k); Paste()
        Scale(${scale_calt_decimal}, ${scale_calt_decimal}, ${width_hankaku} / 2, 0)
        SetWidth(${width_hankaku})
 #        AddPosSub(lookupSub0, glyphName) # ノーマル←小数
        glyphName = GlyphInfo("Name")
        Select(0u0030 + j) # 0
        AddPosSub(lookupSub1, glyphName) # 小数←ノーマル
        k += 1
        j += 1
    endloop

    lookupName = "単純置換 (上下)"
    AddLookup(lookupName, "gsub_single", 0, [], lookups[numlookups - 1])
    lookupSub1 = lookupName + "サブテーブル"
    AddLookupSubtable(lookupName, lookupSub1)

    Select(0u007c); Copy() # |
    glyphName = GlyphInfo("Name")
    Select(k); Paste()
    Move(0, ${move_y_calt_bar})
    SetWidth(${width_hankaku})
 #    AddPosSub(lookupSub0, glyphName) # 移動前←後
    glyphName = GlyphInfo("Name")
    Select(0u007c) # |
    AddPosSub(lookupSub1, glyphName) # 移動前→後
    k += 1

    Select(0u007e); Copy() # ~
    glyphName = GlyphInfo("Name")
    Select(k); Paste()
    Move(0, ${move_y_calt_tilde})
    SetWidth(${width_hankaku})
 #    AddPosSub(lookupSub0, glyphName) # 移動前←後
    glyphName = GlyphInfo("Name")
    Select(0u007e) # ~
    AddPosSub(lookupSub1, glyphName) # 移動前→後
    k += 1

    Select(0u003a); Copy() # :
    glyphName = GlyphInfo("Name")
    Select(k); Paste()
    Move(${move_x_calt_colon}, ${move_y_calt_colon})
    SetWidth(${width_hankaku})
 #    AddPosSub(lookupSub0, glyphName) # 移動前←後
    glyphName = GlyphInfo("Name")
    Select(0u003a) # :
    AddPosSub(lookupSub1, glyphName) # 移動前→後
    k += 1

    lookupName = "単純置換 (上下 2)"
    AddLookup(lookupName, "gsub_single", 0, [], lookups[numlookups - 1])
    lookupSub1 = lookupName + "サブテーブル"
    AddLookupSubtable(lookupName, lookupSub1)

    Select(0u002a); Copy() # *
    glyphName = GlyphInfo("Name")
    Select(k); Paste()
    Move(0, ${move_y_calt_math})
    SetWidth(${width_hankaku})
 #    AddPosSub(lookupSub0, glyphName) # 移動前←後
    glyphName = GlyphInfo("Name")
    Select(0u002a) # *
    AddPosSub(lookupSub1, glyphName) # 移動前→後
    k += 1

    Select(0u002b); Copy() # +
    glyphName = GlyphInfo("Name")
    Select(k); Paste()
    Move(0, ${move_y_calt_math})
    SetWidth(${width_hankaku})
 #    AddPosSub(lookupSub0, glyphName) # 移動前←後
    glyphName = GlyphInfo("Name")
    Select(0u002b) # +
    AddPosSub(lookupSub1, glyphName) # 移動前→後
    k += 1

    Select(0u002d); Copy() # -
    glyphName = GlyphInfo("Name")
    Select(k); Paste()
    Move(0, ${move_y_calt_math})
    SetWidth(${width_hankaku})
 #    AddPosSub(lookupSub0, glyphName) # 移動前←後
    glyphName = GlyphInfo("Name")
    Select(0u002d) # -
    AddPosSub(lookupSub1, glyphName) # 移動前→後
    k += 1

    Select(0u003d); Copy() # =
    glyphName = GlyphInfo("Name")
    Select(k); Paste()
    Move(0, ${move_y_calt_math})
    SetWidth(${width_hankaku})
 #    AddPosSub(lookupSub0, glyphName) # 移動前←後
    glyphName = GlyphInfo("Name")
    Select(0u003d) # =
    AddPosSub(lookupSub1, glyphName) # 移動前→後
    k += 1

    Select(0u007c); Copy() # |
    glyphName = GlyphInfo("Name")
    Select(k); Paste()
    Move(0, ${move_y_calt_bar2})
    SetWidth(${width_hankaku})
 #    AddPosSub(lookupSub0, glyphName) # 移動前←後
    glyphName = GlyphInfo("Name")
    Select(0u007c) # |
    AddPosSub(lookupSub1, glyphName) # 移動前→後
    k += 1

    Select(0u003a); Copy() # :
    glyphName = GlyphInfo("Name")
    Select(k); Paste()
    Move(${move_x_calt_colon}, ${move_y_calt_colon2})
    SetWidth(${width_hankaku})
 #    AddPosSub(lookupSub0, glyphName) # 移動前←後
    glyphName = GlyphInfo("Name")
    Select(0u003a) # :
    AddPosSub(lookupSub1, glyphName) # 移動前→後
    k += 1

    lookupName = "単純置換 (左・記号)"
    AddLookup(lookupName, "gsub_single", 0, [], lookups[numlookups - 1])
    lookupSub1 = lookupName + "サブテーブル"
    AddLookupSubtable(lookupName, lookupSub1)

    symb = [0u002a, 0u002b, 0u002d, 0u003d, 0u005f,\
            0u002f, 0u005c, 0u003c, 0u003e,\
            0u0028, 0u0029, 0u005b, 0u005d,\
            0u007b, 0u007d,\
            0u0021, 0u0022, 0u0027, 0u002c,\
            0u002e, 0u003a, 0u003b, 0u003f,\
            0u0060, 0u007c, 0u0000, 0u0001, 0u0002,\
            0u0003, 0u0004] # *+-=_solidus reverse solidus<>()[]{}!quote apostrophe,.:;?grave|、移動した|~:|:
    j = 0
    while (j < SizeOf(symb))
        if (symb[j] == 0u0000) # 移動した |
            Select(${address_calt_barD})
        elseif (symb[j] == 0u0001) # 移動した ~
            Select(${address_calt_barD} + 1)
        elseif (symb[j] == 0u0002) # 移動した :
            Select(${address_calt_barD} + 2)
        elseif (symb[j] == 0u0003) # 移動した |
            Select(${address_calt_barD} + 7)
        elseif (symb[j] == 0u0004) # 移動した :
            Select(${address_calt_barD} + 8)
        else
            Select(symb[j])
        endif
        Copy()
        glyphName = GlyphInfo("Name")
        Select(k); Paste()
        Move(-${move_x_calt_symbol}, 0)
        SetWidth(${width_hankaku})
        AddPosSub(lookupSub0, glyphName) # 左→中
        glyphName = GlyphInfo("Name")
        if (symb[j] == 0u0000) # 移動した |
            Select(${address_calt_barD})
        elseif (symb[j] == 0u0001) # 移動した ~
            Select(${address_calt_barD} + 1)
        elseif (symb[j] == 0u0002) # 移動した :
            Select(${address_calt_barD} + 2)
        elseif (symb[j] == 0u0003) # 移動した |
            Select(${address_calt_barD} + 7)
        elseif (symb[j] == 0u0004) # 移動した :
            Select(${address_calt_barD} + 8)
        else
            Select(symb[j])
        endif
        AddPosSub(lookupSub1, glyphName) # 左←中
        j += 1
        k += 1
    endloop

    lookupName = "単純置換 (右・記号)"
    AddLookup(lookupName, "gsub_single", 0, [], lookups[numlookups - 1])
    lookupSub1 = lookupName + "サブテーブル"
    AddLookupSubtable(lookupName, lookupSub1)

    j = 0
    while (j < SizeOf(symb))
        if (symb[j] == 0u0000) # 移動した |
            Select(${address_calt_barD})
        elseif (symb[j] == 0u0001) # 移動した ~
            Select(${address_calt_barD} + 1)
        elseif (symb[j] == 0u0002) # 移動した :
            Select(${address_calt_barD} + 2)
        elseif (symb[j] == 0u0003) # 移動した |
            Select(${address_calt_barD} + 7)
        elseif (symb[j] == 0u0004) # 移動した :
            Select(${address_calt_barD} + 8)
        else
            Select(symb[j])
        endif
        Copy()
        glyphName = GlyphInfo("Name")
        Select(k); Paste()
        Move(${move_x_calt_symbol}, 0)
        SetWidth(${width_hankaku})
        AddPosSub(lookupSub0, glyphName) # 左→中
        glyphName = GlyphInfo("Name")
        if (symb[j] == 0u0000) # 移動した |
            Select(${address_calt_barD})
        elseif (symb[j] == 0u0001) # 移動した ~
            Select(${address_calt_barD} + 1)
        elseif (symb[j] == 0u0002) # 移動した :
            Select(${address_calt_barD} + 2)
        elseif (symb[j] == 0u0003) # 移動した |
            Select(${address_calt_barD} + 7)
        elseif (symb[j] == 0u0004) # 移動した :
            Select(${address_calt_barD} + 8)
        else
            Select(symb[j])
        endif
        AddPosSub(lookupSub1, glyphName) # 左←中
        j += 1
        k += 1
    endloop

    # calt をスクリプトで扱う方法が分からないので一旦ダミーをセットしてttxで上書きする
    j = 0
    while (j < ${num_calt_lookups}) # caltルックアップの数だけ確保する
        lookupName = "'zero' 文脈依存の異体字に後で換える " + ToString(j)
        AddLookup(lookupName, "gsub_single", 0, [["zero",[["DFLT",["dflt"]]]]], lookups[numlookups - 1])
        Select(0u00a0); glyphName = GlyphInfo("Name")
        Select(0u0020)

        lookupSub = lookupName + "サブテーブル"
        AddLookupSubtable(lookupName, lookupSub)
        AddPosSub(lookupSub, glyphName)
        j += 1
    endloop

# ss 対応 (lookup の数を変えた場合は table_modificator も変更すること)
    Print("Add ss lookups")
    lookups = GetLookups("GSUB"); numlookups = SizeOf(lookups)

    j = ${num_ss_lookups}
    while (0 < j) # ssルックアップの数だけ確保する
        if (j < 10)
            lookupName = "'ss0" + ToString(j) + "' スタイルセット" + ToString(j)
            AddLookup(lookupName, "gsub_single", 0, [["ss0" + ToString(j),[["DFLT",["dflt"]]]]], lookups[numlookups - 1])
        else
            lookupName = "'ss" + ToString(j) + "' スタイルセット" + ToString(j)
            AddLookup(lookupName, "gsub_single", 0, [["ss" + ToString(j),[["DFLT",["dflt"]]]]], lookups[numlookups - 1])
        endif
        lookupSub = lookupName + "サブテーブル"
        AddLookupSubtable(lookupName, lookupSub)
        j -= 1
    endloop

    ss = 1
# ss01 全角スペース
    lookupName = "'ss0" + ToString(ss) + "' スタイルセット" + ToString(ss)
    lookupSub = lookupName + "サブテーブル"

    orig = [0u3000] # 全角スペース
    j = 0
    while (j < SizeOf(orig))
        Select(orig[j]); Copy()
        Select(k); Paste()
        SetWidth(${width_zenkaku})
        glyphName = GlyphInfo("Name")
        Select(orig[j])
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
    endloop

    ss += 1
# ss02 半角スペース
    lookupName = "'ss0" + ToString(ss) + "' スタイルセット" + ToString(ss)
    lookupSub = lookupName + "サブテーブル"

    orig = [0u0020, 0u00a0] # space, no-break space
    j = 0
    while (j < SizeOf(orig))
        Select(orig[j]); Copy()
        Select(k); Paste()
        SetWidth(${width_hankaku})
        glyphName = GlyphInfo("Name")
        Select(orig[j])
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
    endloop

    ss += 1
# ss03・ss04・ss05 桁区切りマーク、小数
    j = 0
    while (j < 40)
        Select(${address_calt_figure} + j); Copy() # 桁区切りマーク付き数字
        Select(k); Paste()
        SetWidth(${width_hankaku})
        glyphName = GlyphInfo("Name")
        Select(${address_calt_figure} + j);
        if (j < 10) # 3桁 (3桁のみ変換)
            lookupName = "'ss0" + ToString(ss) + "' スタイルセット" + ToString(ss)
            lookupSub = lookupName + "サブテーブル"
            AddPosSub(lookupSub, glyphName)
        endif
        if (10 <= j && j < 20) # 4桁 (4桁のみ変換)
            lookupName = "'ss0" + ToString(ss + 1) + "' スタイルセット" + ToString(ss + 1)
            lookupSub = lookupName + "サブテーブル"
            AddPosSub(lookupSub, glyphName)
        endif
        if (20 <= j && j < 30) # 4桁 (12桁を4桁に変換)
            Select(k - 10)
            glyphName = GlyphInfo("Name")
            Select(${address_calt_figure} + j);
            lookupName = "'ss0" + ToString(ss + 1) + "' スタイルセット" + ToString(ss + 1)
            lookupSub = lookupName + "サブテーブル"
            AddPosSub(lookupSub, glyphName)
        endif
        if (30 <= j) # 小数
            lookupName = "'ss0" + ToString(ss + 2) + "' スタイルセット" + ToString(ss + 2)
            lookupSub = lookupName + "サブテーブル"
            AddPosSub(lookupSub, glyphName)
        endif
        j += 1
        k += 1
    endloop

    j = 0
    while (j < 10)
        Select(${address_calt_figure} + j); Copy() # 桁区切りマーク付き数字
        Select(k); Paste() # 3桁 (3桁に偽装した12桁を作成)
        SetWidth(${width_hankaku})
        glyphName = GlyphInfo("Name")
        Select(${address_calt_figure} + 20 + j);
        lookupName = "'ss0" + ToString(ss) + "' スタイルセット" + ToString(ss)
        lookupSub = lookupName + "サブテーブル"
        AddPosSub(lookupSub, glyphName)
        Select(k - 20); # 3桁 + 4桁 (偽装した3桁から12桁に戻す)
        glyphName = GlyphInfo("Name")
        Select(k)
        lookupName = "'ss0" + ToString(ss + 1) + "' スタイルセット" + ToString(ss + 1)
        lookupSub = lookupName + "サブテーブル"
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
    endloop

    ss += 3
# ss06 下線
    lookupName = "'ss0" + ToString(ss) + "' スタイルセット" + ToString(ss)
    lookupSub = lookupName + "サブテーブル"

    j = 0 # デフォルトで下線有りにする場合
    l = 0
    while (j < 109) # 全角縦書き
        if (j == 48)
            Select(${address_store_mod} + ${num_mod_glyphs} * 2) # 縦書きＤ
        elseif (j == 61)
            Select(${address_store_mod} + ${num_mod_glyphs} * 2 + 1) # 縦書きＱ
        elseif (j == 66)
            Select(${address_store_mod} + ${num_mod_glyphs} * 2 + 2) # 縦書きＶ
        elseif (j == 70)
            Select(${address_store_mod} + ${num_mod_glyphs} * 2 + 3) # 縦書きＺ
        else
            Select(${address_store_vert} + l)
        endif
        Copy()
        Select(k); Paste()
        SetWidth(${width_zenkaku})
        glyphName = GlyphInfo("Name")
        Select(${address_vert_bracket} + j)
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
        l += 1
    endloop

    j = 0
    while (j < 159) # 全角半角横書き
        if (j == 35)
            Select(${address_store_mod} + ${num_mod_glyphs}) # Ｄ
        elseif (j == 48)
            Select(${address_store_mod} + ${num_mod_glyphs} + 1) # Ｑ
        elseif (j == 53)
            Select(${address_store_mod} + ${num_mod_glyphs} + 2) # Ｖ
        elseif (j == 57)
            Select(${address_store_mod} + ${num_mod_glyphs} + 3) # Ｚ
        else
            Select(${address_store_vert} + l)
        endif
        Copy()
        Select(k); Paste()
        if (j < 96)
            SetWidth(${width_zenkaku})
        else
            SetWidth(${width_hankaku})
        endif
        glyphName = GlyphInfo("Name")
        Select(0uff01 + j)
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
        l += 1
    endloop

    j = 0
    while (j < 7) # ￠-￦
        Select(${address_store_vert} + l); Copy()
        Select(k); Paste()
        SetWidth(${width_zenkaku})
        glyphName = GlyphInfo("Name")
        Select(0uffe0 + j)
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
        l += 1
    endloop

    orig = [0u309b, 0u309c, 0u203c, 0u2047,\
            0u2048, 0u2049] # ゛゜‼⁇ ⁈⁉
    j = 0
    while (j < SizeOf(orig))
        if (2 <= j && "${term_flag}" == "true")
            Select(orig[j]); Copy()
            Select(k); Paste()
            SetWidth(${width_hankaku})
        else
            Select(${address_store_vert} + l); Copy()
            Select(k); Paste()
            SetWidth(${width_zenkaku})
        endif
        glyphName = GlyphInfo("Name")
        Select(orig[j])
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
        l += 1
    endloop

    j = 0
    while (j < 256) # 点字
        Select(${address_store_braille} + j); Copy()
        Select(k); Paste()
        SetWidth(${width_hankaku})
        glyphName = GlyphInfo("Name")
        Select(0u2800 + j)
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
    endloop

 #      j = 0 # デフォルトで下線無しにする場合
 #      while (j < 109) # 全角縦書き
 #          if (j == 48)
 #              Select(${address_store_mod} + ${num_mod_glyphs} * 5) # 縦書きＤ
 #          elseif (j == 61)
 #              Select(${address_store_mod} + ${num_mod_glyphs} * 5 + 1) # 縦書きＱ
 #          elseif (j == 66)
 #              Select(${address_store_mod} + ${num_mod_glyphs} * 5 + 2) # 縦書きＶ
 #          elseif (j == 70)
 #              Select(${address_store_mod} + ${num_mod_glyphs} * 5 + 3) # 縦書きＺ
 #          else
 #              Select(${address_vert_bracket} + j)
 #          endif
 #          Copy()
 #          Select(k); Paste()
 #          SetWidth(${width_zenkaku})
 #          glyphName = GlyphInfo("Name")
 #          Select(${address_vert_bracket} + j)
 #          AddPosSub(lookupSub, glyphName)
 #          j += 1
 #          k += 1
 #      endloop
 #
 #    j = 0
 #    while (j < 159) # 全角半角横書き
 #        if (j == 35)
 #            Select(${address_store_mod} + ${num_mod_glyphs} * 4) # Ｄ
 #        elseif (j == 48)
 #            Select(${address_store_mod} + ${num_mod_glyphs} * 4 + 1) # Ｑ
 #        elseif (j == 53)
 #            Select(${address_store_mod} + ${num_mod_glyphs} * 4 + 2) # Ｖ
 #        elseif (j == 57)
 #            Select(${address_store_mod} + ${num_mod_glyphs} * 4 + 3) # Ｚ
 #        else
 #            Select(0uff01 + j)
 #        endif
 #        Copy()
 #        Select(k); Paste()
 #        if (j < 96)
 #            SetWidth(${width_zenkaku})
 #        else
 #            SetWidth(${width_hankaku})
 #        endif
 #        glyphName = GlyphInfo("Name")
 #        Select(0uff01 + j)
 #        AddPosSub(lookupSub, glyphName)
 #        j += 1
 #        k += 1
 #    endloop
 #
 #    j = 0
 #    while (j < 7) # ￠-￦
 #        Select(0uffe0 + j); Copy()
 #        Select(k); Paste()
 #        SetWidth(${width_zenkaku})
 #        glyphName = GlyphInfo("Name")
 #        Select(0uffe0 + j)
 #        AddPosSub(lookupSub, glyphName)
 #        j += 1
 #        k += 1
 #    endloop
 #
 #    orig = [0u309b, 0u309c, 0u203c, 0u2047,\
 #            0u2048, 0u2049] # ゛゜‼⁇ ⁈⁉
 #    j = 0
 #    while (j < SizeOf(orig))
 #        Select(orig[j]); Copy()
 #        Select(k); Paste()
 #        if (2 <= j && "${term_flag}" == "true")
 #            SetWidth(${width_hankaku})
 #        else
 #            SetWidth(${width_zenkaku})
 #        endif
 #        glyphName = GlyphInfo("Name")
 #        Select(orig[j])
 #        AddPosSub(lookupSub, glyphName)
 #        j += 1
 #        k += 1
 #    endloop
 #
 #    j = 0
 #    while (j < 256) # 点字
 #        Select(0u2800 + j); Copy()
 #        Select(k); Paste()
 #        SetWidth(${width_hankaku})
 #        glyphName = GlyphInfo("Name")
 #        Select(0u2800 + j)
 #        AddPosSub(lookupSub, glyphName)
 #        j += 1
 #        k += 1
 #    endloop

    ss += 1
# ss07 破線・ウロコ
    lookupName = "'ss0" + ToString(ss) + "' スタイルセット" + ToString(ss)
    lookupSub = lookupName + "サブテーブル"

    orig = [0u2044, 0u007c,\
            0u30a0, 0u2f23, 0u2013, 0ufe32, 0u2014, 0ufe31] # ⁄| ゠⼣–︲—︱
    j = 0
    l = 0
    while (j < SizeOf(orig))
        Select(${address_store_visi_latin} + l); Copy()
        Select(k); Paste()
        if (j <= 1 || j == 4)
            SetWidth(${width_hankaku})
        elseif (j == 6 && "${term_flag}" == "true")
            SetWidth(${width_hankaku})
        else
            SetWidth(${width_zenkaku})
        endif
        glyphName = GlyphInfo("Name")
        Select(orig[j])
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
        l += 1
    endloop

    j = 0
    while (j < 20) # ➀-➓
        Select(${address_store_visi_latin} + l); Copy()
        Select(k); Paste()
        if ("${term_flag}" == "true")
            SetWidth(${width_hankaku})
        else
            SetWidth(${width_zenkaku})
        endif
        glyphName = GlyphInfo("Name")
        Select(0u2780 + j)
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
        l += 1
    endloop

    orig = [0u3007, 0u4e00, 0u4e8c, 0u4e09,\
            0u5de5, 0u529b, 0u5915, 0u535c,\
            0u53e3] # 〇一二三 工力夕卜 口
    j = 0
    while (j < SizeOf(orig))
        Select(${address_store_visi_latin} + l); Copy()
        Select(k); Paste()
        SetWidth(${width_zenkaku})
        glyphName = GlyphInfo("Name")
        Select(orig[j])
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
        l += 1
    endloop

    Select(${address_store_d_hyphen}); Copy() # 縦書き゠
    Select(k); Paste()
    SetWidth(${width_zenkaku})
    glyphName = GlyphInfo("Name")
    Select(${address_vert_dh})
    AddPosSub(lookupSub, glyphName)
    k += 1

    Select(${address_store_visi_latin} + 1); Copy() # 左に移動した |
    Select(k); Paste()
    Move(-${move_x_calt_symbol}, 0)
    SetWidth(${width_hankaku})
    glyphName = GlyphInfo("Name")
    Select(${address_calt_hyphenL} + ${address_calt_barDLR})
    AddPosSub(lookupSub, glyphName)
    k += 1

    Select(${address_store_visi_latin} + 1); Copy() # 右に移動した |
    Select(k); Paste()
    Move(${move_x_calt_symbol}, 0)
    SetWidth(${width_hankaku})
    glyphName = GlyphInfo("Name")
    Select(${address_calt_hyphenR} + ${address_calt_barDLR})
    AddPosSub(lookupSub, glyphName)
    k += 1

    Select(${address_store_visi_latin} + 1); Copy() # 下に移動した |
    Select(k); Paste()
    Move(0, ${move_y_calt_bar})
    SetWidth(${width_hankaku})
    glyphName = GlyphInfo("Name")
    Select(${address_calt_barD})
    AddPosSub(lookupSub, glyphName)
    k += 1

    Select(${address_store_visi_latin} + 1); Copy() # 左下に移動した |
    Select(k); Paste()
    Move(-${move_x_calt_symbol}, ${move_y_calt_bar})
    SetWidth(${width_hankaku})
    glyphName = GlyphInfo("Name")
    Select(${address_calt_hyphenL} + ${address_calt_barDLR} + 1)
    AddPosSub(lookupSub, glyphName)
    k += 1

    Select(${address_store_visi_latin} + 1); Copy() # 右下に移動した |
    Select(k); Paste()
    Move(${move_x_calt_symbol}, ${move_y_calt_bar})
    SetWidth(${width_hankaku})
    glyphName = GlyphInfo("Name")
    Select(${address_calt_hyphenR} + ${address_calt_barDLR} + 1)
    AddPosSub(lookupSub, glyphName)
    k += 1

    Select(${address_store_visi_latin} + 1); Copy() # 上に移動した | (括弧用)
    Select(k); Paste()
    Move(0, ${move_y_calt_bar2})
    SetWidth(${width_hankaku})
    glyphName = GlyphInfo("Name")
    Select(${address_calt_barD} + 7)
    AddPosSub(lookupSub, glyphName)
    k += 1

    Select(${address_store_visi_latin} + 1); Copy() # 左上に移動した | (括弧用)
    Select(k); Paste()
    Move(-${move_x_calt_symbol}, ${move_y_calt_bar2})
    SetWidth(${width_hankaku})
    glyphName = GlyphInfo("Name")
    Select(${address_calt_hyphenL} + ${address_calt_barDLR} + 4)
    AddPosSub(lookupSub, glyphName)
    k += 1

    Select(${address_store_visi_latin} + 1); Copy() # 右上に移動した | (括弧用)
    Select(k); Paste()
    Move(${move_x_calt_symbol}, ${move_y_calt_bar2})
    SetWidth(${width_hankaku})
    glyphName = GlyphInfo("Name")
    Select(${address_calt_hyphenR} + ${address_calt_barDLR} + 4)
    AddPosSub(lookupSub, glyphName)
    k += 1

    if ("${liga_flag}" == "true")
        Select(${address_store_liga}); Copy() # ||
        Select(k); Paste()
        SetWidth(${width_hankaku})
        glyphName = GlyphInfo("Name")
        Select(0ue104)
        AddPosSub(lookupSub, glyphName)
        k += 1
    endif

    ss += 1
# ss08 DQVZ
    lookupName = "'ss0" + ToString(ss) + "' スタイルセット" + ToString(ss)
    lookupSub = lookupName + "サブテーブル"

    orig = [0u0044, 0u0051, 0u0056, 0u005A] # DQVZ
    num = [3, 16, 21, 25] # 左に移動したAからDQVZまでの数
    j = 0
    while (j < SizeOf(orig))
        Select(orig[j]); Copy()
        Select(k); Paste()
        SetWidth(${width_hankaku})
        glyphName = GlyphInfo("Name")
        Select(orig[j])
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
    endloop

    j = 0
    while (j < SizeOf(orig)) # 左に移動したDQVZ
        Select(orig[j]); Copy()
        Select(k); Paste()
        Move(-${move_x_calt_latin}, 0)
        SetWidth(${width_hankaku})
        glyphName = GlyphInfo("Name")
        Select(${address_calt_AL} + num[j])
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
    endloop

    j = 0
    while (j < SizeOf(orig)) # 右に移動したDQVZ
        Select(orig[j]); Copy()
        Select(k); Paste()
        Move(${move_x_calt_latin}, 0)
        SetWidth(${width_hankaku})
        glyphName = GlyphInfo("Name")
        Select(${address_calt_AR} + num[j])
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
    endloop

 # (デフォルトで下線無しにする場合はコメントアウトを変更し、glyphName を付加する Select 対象を変える)
    orig = [0uff24, 0uff31, 0uff36, 0uff3a] # 全角横書きDQVZ
    num0 = [35, 48, 53, 57] # 全角横書きDQVZ ！から全角DQVZまでの数
    num1 = [48, 61, 66, 70] # 全角縦書きDQVZ （から全角DQVZまでの数

    j = 0
    while (j < SizeOf(orig))
        Select(orig[j]); Copy() # 下線付き横書き
        Select(k); Paste()
        SetWidth(${width_zenkaku})
        glyphName = GlyphInfo("Name")
        Select(orig[j]) # 変換前横書き
 #        Select(${address_ss_zenhan} + num0[j]) # ss変換後横書き
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
    endloop

    j = 0
    while (j < SizeOf(orig))
        Select(${address_vert_bracket} + num1[j]); Copy() # 下線付き縦書き
        Select(k); Paste()
        SetWidth(${width_zenkaku})
        glyphName = GlyphInfo("Name")
        Select(${address_vert_bracket} + num1[j]) # vert変換後ss変換前縦書き
 #        Select(${address_ss_vert} + num1[j]) # ss変換後縦書き
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
    endloop

    j = 0
    while (j < SizeOf(orig))
        Select(${address_store_vert} + num1[j]); Copy() # 下線無し全角
        Select(k); Paste()
        SetWidth(${width_zenkaku})
        glyphName = GlyphInfo("Name")
        Select(${address_ss_zenhan} + num0[j]) # ss変換後横書き
 #        Select(orig[j]) # 変換前横書き
        AddPosSub(lookupSub, glyphName)
        Select(${address_ss_vert} + num1[j]) # ss変換後縦書き
 #        Select(${address_vert_bracket} + num1[j]) # vert変換後ss変換前縦書き
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
    endloop

    ss += 1
# ss09 罫線
    lookupName = "'ss0" + ToString(ss) + "' スタイルセット" + ToString(ss)
    lookupSub = lookupName + "サブテーブル"

    line = [0u2500, 0u2501, 0u2502, 0u2503, 0u250c, 0u250f,\
            0u2510, 0u2513, 0u2514, 0u2517, 0u2518, 0u251b, 0u251c, 0u251d,\
            0u2520, 0u2523, 0u2524, 0u2525, 0u2528, 0u252b, 0u252c, 0u252f,\
            0u2530, 0u2533, 0u2534, 0u2537, 0u2538, 0u253b, 0u253c, 0u253f,\
            0u2542, 0u254b] # 全角罫線
    j = 0
    while (j < SizeOf(line))
        Select(${address_store_line} + j); Copy()
        Select(k); Paste()
        SetWidth(${width_zenkaku})
        glyphName = GlyphInfo("Name")
        Select(line[j])
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
    endloop

    arrow = [0u2190, 0u2191, 0u2192, 0u2193] # ←↑→↓
    j = 0
    while (j < SizeOf(arrow))
        Select(${address_store_arrow} + j); Copy()
        Select(k); Paste()
        SetWidth(${width_zenkaku})
        glyphName = GlyphInfo("Name")
        Select(arrow[j])
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
    endloop

    ss += 1
# ss10 スラッシュ無し0
    lookupName = "'ss" + ToString(ss) + "' スタイルセット" + ToString(ss)
    lookupSub = lookupName + "サブテーブル"

    zero = [0u0030, 0u2070, 0u2080] # 0⁰₀
    j = 0
    while (j < SizeOf(zero))
        Select(${address_store_zero} + j); Copy()
        Select(k); Paste()
        SetWidth(${width_hankaku})
        glyphName = GlyphInfo("Name")
        Select(zero[j])
        AddPosSub(lookupSub, glyphName)
        if (j == 0)
            Select(${address_calt_figure}) # caltで変換したグリフ (3桁) からの変換
            AddPosSub(lookupSub, glyphName)
            Select(${address_calt_figure} + 10) # caltで変換したグリフ (4桁) からの変換
            AddPosSub(lookupSub, glyphName)
            Select(${address_calt_figure} + 20) # caltで変換したグリフ (12桁) からの変換
            AddPosSub(lookupSub, glyphName)
            Select(${address_calt_figure} + 30) # caltで変換したグリフ (小数) からの変換
            AddPosSub(lookupSub, glyphName)
        endif
        j += 1
        k += 1
    endloop

    # 3桁区切り
    Select(${address_store_b_diagram}); Copy() # 保管した▲
    Select(k); Paste()
    Scale(15, 27)
    Move(${move_x_calt_separate}, ${move_y_calt_separate3})
    Copy(); Select(k + 2); Paste() # 12桁用
    Select(${address_store_zero}); Copy()
    Select(k); PasteInto()
    SetWidth(${width_hankaku})
    glyphName = GlyphInfo("Name")
    Select(${address_ss_figure}) # ssで変換したグリフからの変換
    AddPosSub(lookupSub, glyphName)
    Select(${address_ss_figure} + 40) # ssで変換したグリフ (3桁に偽装した12桁) からの変換
    AddPosSub(lookupSub, glyphName)
    k += 1

    # 4桁区切り
    Select(${address_store_b_diagram} + 1); Copy() # 保管した▼
    Select(k); Paste()
    Scale(15, 27)
    Move(${move_x_calt_separate}, ${move_y_calt_separate4})
    Copy(); Select(k + 1); PasteInto() # 12桁用
    Select(${address_store_zero}); Copy()
    Select(k); PasteInto()
    SetWidth(${width_hankaku})
    glyphName = GlyphInfo("Name")
    Select(${address_ss_figure} + 10) # ssで変換したグリフからの変換
    AddPosSub(lookupSub, glyphName)
    k += 1

    # 12桁区切り
    Select(${address_store_zero}); Copy()
    Select(k); PasteInto()
    SetWidth(${width_hankaku})
    glyphName = GlyphInfo("Name")
    Select(${address_ss_figure} + 20) # ssで変換したグリフからの変換
    AddPosSub(lookupSub, glyphName)
    k += 1

    # 小数
    Select(${address_store_zero}); Copy() # スラッシュ無し0
    Select(k); Paste()
    Scale(${scale_calt_decimal}, ${scale_calt_decimal}, ${width_hankaku} / 2, 0)
    SetWidth(${width_hankaku})
    glyphName = GlyphInfo("Name")
    Select(${address_ss_figure} + 30) # ssで変換したグリフからの変換
    AddPosSub(lookupSub, glyphName)
    k += 1

    # 全角
    # (デフォルトで下線無しにする場合はコメントアウトを変更し、glyphName を付加する Select 対象を変える)

    Select(${address_store_zero} + 4); Copy() # 下線付き横書き
    Select(k); Paste()
    SetWidth(${width_zenkaku})
    glyphName = GlyphInfo("Name")
    Select(0uff10) # 変換前横書き
 #    Select(${address_ss_zenhan} + 15) # ss変換後横書き
    AddPosSub(lookupSub, glyphName)
    k += 1

    Select(${address_store_zero} + 5); Copy() # 下線付き縦書き
    Select(k); Paste()
    SetWidth(${width_zenkaku})
    glyphName = GlyphInfo("Name")
    Select(${address_vert_bracket} + 33) # vert変換後ss変換前縦書き
 #    Select(${address_ss_vert} + 33) # ss変換後縦書き
    AddPosSub(lookupSub, glyphName)
    k += 1

    Select(${address_store_zero} + 3); Copy() # 下線無し全角
    Select(k); Paste()
    SetWidth(${width_zenkaku})
    glyphName = GlyphInfo("Name")
    Select(${address_ss_zenhan} + 15) # ss変換後横書き
 #    Select(0uff10) # 変換前横書き
    AddPosSub(lookupSub, glyphName)
    Select(${address_ss_vert} + 33) # ss変換後縦書き
 #    Select(${address_vert_bracket} + 33) # vert変換後ss変換前縦書き
    AddPosSub(lookupSub, glyphName)
    k += 1

    ss += 1
# ss11 その他のスペース可視化
    lookupName = "'ss" + ToString(ss) + "' スタイルセット" + ToString(ss)
    lookupSub = lookupName + "サブテーブル"

    Select(${address_store_otherspace}); Copy() # その他の全角スペース
    Select(k); Paste()

    spc =[\
    0u2001,\
    0u2003\
    ]
    j = 0
    while (j < SizeOf(spc))
        Select(k)
        glyphName = GlyphInfo("Name")
        Select(spc[j])
        AddPosSub(lookupSub, glyphName)
        j += 1
    endloop
    k += 1

    Select(${address_store_otherspace} + 1); Copy() # その他の半角・幅無しスペース
    Select(k); Paste()

    spc =[\
    0u034f,\
    0u2000,\
    0u2002,\
    0u2004,\
    0u2005,\
    0u2006,\
    0u2007,\
    0u2008,\
    0u2009,\
    0u200a,\
    0u200b,\
    0u200c,\
    0u200d,\
    0u202f,\
    0u205f,\
    0u2060,\
    0ufeff\
    ]
    j = 0
    while (j < SizeOf(spc))
        Select(k)
        glyphName = GlyphInfo("Name")
        Select(spc[j])
        AddPosSub(lookupSub, glyphName)
        j += 1
    endloop
    k += 1

    ss += 1
# ss12 一部のあいまい文字等を半角化
    lookupName = "'ss" + ToString(ss) + "' スタイルセット" + ToString(ss)
    lookupSub = lookupName + "サブテーブル"

    orig = [0u2025, 0u2026] # ‥…
    j = 0
    while (j < SizeOf(orig))
        Select(orig[j]); Copy()
        Select(k); Paste()
        if (600 <= GlyphInfo("Width"))
            Scale(${scale_zenkaku2hankaku} * ${width_hankaku} / ${width_hankaku_loose}, 100, ${width_zenkaku} / 2, 0)
            Move(-(${width_zenkaku} / 2 - ${width_hankaku} / 2), 0)
            Copy()
            PasteWithOffset(-10 * ${width_hankaku_loose} / ${width_hankaku}, 0)
            PasteWithOffset( 10 * ${width_hankaku_loose} / ${width_hankaku}, 0)
            RemoveOverlap()
        endif
        SetWidth(${width_hankaku})
        glyphName = GlyphInfo("Name")
        Select(orig[j])
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
    endloop

    orig = [0u203b] # ※
    j = 0
    while (j < SizeOf(orig))
        Select(orig[j]); Copy()
        Select(k); Paste()
        if (600 <= GlyphInfo("Width"))
            Scale(${scale_zenkaku2hankaku} * ${width_hankaku} / ${width_hankaku_loose}, 100, ${width_zenkaku} / 2, 0)
            Move(-(${width_zenkaku} / 2 - ${width_hankaku} / 2), 0)
        endif
        SetWidth(${width_hankaku})
        glyphName = GlyphInfo("Name")
        Select(orig[j])
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
    endloop

    orig = [0u2103, 0u2109] # ℃℉
    j = 0
    while (j < SizeOf(orig))
        Select(orig[j]); Copy()
        Select(k); Paste()
        if (600 <= GlyphInfo("Width"))
            Scale(${scale_zenkaku2hankaku} * ${width_hankaku} / ${width_hankaku_loose} * 1.2, 100, ${width_zenkaku} / 2, 0)
            Move(-(${width_zenkaku} / 2 - ${width_hankaku} / 2), 0)
        endif
        SetWidth(${width_hankaku})
        glyphName = GlyphInfo("Name")
        Select(orig[j])
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
    endloop

    j = 0
    while (j < 12)
        Select(0u2160 + j); Copy() # Ⅰ-Ⅻ
        Select(k); Paste()
        if (600 <= GlyphInfo("Width"))
            Scale(${scale_zenkaku2hankaku} * ${width_hankaku} / ${width_hankaku_loose}, 100, ${width_zenkaku} / 2, 0)
            Move(-(${width_zenkaku} / 2 - ${width_hankaku} / 2), 0)
        endif
        SetWidth(${width_hankaku})
        glyphName = GlyphInfo("Name")
        Select(0u2160 + j)
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
    endloop

    j = 0
    while (j < 12)
        Select(0u2170 + j); Copy() # ⅰ-ⅻ
        Select(k); Paste()
        if (600 <= GlyphInfo("Width"))
            Scale(${scale_zenkaku2hankaku} * ${width_hankaku} / ${width_hankaku_loose}, 100, ${width_zenkaku} / 2, 0)
            Move(-(${width_zenkaku} / 2 - ${width_hankaku} / 2), 0)
        endif
        SetWidth(${width_hankaku})
        glyphName = GlyphInfo("Name")
        Select(0u2170 + j)
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
    endloop

    j = 0
    while (j < 6)
        Select(0u2190 + j); Copy() # ←-↕
        Select(k); Paste()
        if (600 <= GlyphInfo("Width"))
            Scale(${scale_zenkaku2hankaku} * ${width_hankaku} / ${width_hankaku_loose}, ${width_zenkaku} / 2, 340)
            Move(-(${width_zenkaku} / 2 - ${width_hankaku} / 2), 0)
        endif
        SetWidth(${width_hankaku})
        glyphName = GlyphInfo("Name")
        Select(0u2190 + j)
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
    endloop

    j = 0
    while (j < 6)
        Select(0u21d0 + j); Copy() # ⇐-⇕
        Select(k); Paste()
        if (600 <= GlyphInfo("Width"))
            Scale(${scale_zenkaku2hankaku} * ${width_hankaku} / ${width_hankaku_loose}, ${width_zenkaku} / 2, 340)
            Move(-(${width_zenkaku} / 2 - ${width_hankaku} / 2), 0)
        endif
        SetWidth(${width_hankaku})
        glyphName = GlyphInfo("Name")
        Select(0u21d0 + j)
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
    endloop

    j = 0
    while (j < 20)
        Select(0u2460 + j); Copy() # ①-⑳
        Select(k); Paste()
        if (600 <= GlyphInfo("Width"))
            Scale(${scale_zenkaku2hankaku} * ${width_hankaku} / ${width_hankaku_loose} * 0.95, 100, ${width_zenkaku} / 2, 0)
            Move(-(${width_zenkaku} / 2 - ${width_hankaku} / 2), 0)
        endif
        SetWidth(${width_hankaku})
        glyphName = GlyphInfo("Name")
        Select(0u2460 + j)
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
    endloop

    j = 0
    while (j < 11)
        Select(0u24ea + j); Copy() # ⓪-⓴
        Select(k); Paste()
        if (600 <= GlyphInfo("Width"))
            Scale(${scale_zenkaku2hankaku} * ${width_hankaku} / ${width_hankaku_loose} * 0.95, 100, ${width_zenkaku} / 2, 0)
            Move(-(${width_zenkaku} / 2 - ${width_hankaku} / 2), 0)
        endif
        SetWidth(${width_hankaku})
        glyphName = GlyphInfo("Name")
        Select(0u24ea + j)
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
    endloop

    orig = [0u24ff] # ⓿
    j = 0
    while (j < SizeOf(orig))
        Select(orig[j]); Copy()
        Select(k); Paste()
        if (600 <= GlyphInfo("Width"))
            Scale(${scale_zenkaku2hankaku} * ${width_hankaku} / ${width_hankaku_loose} * 0.95, 100, ${width_zenkaku} / 2, 0)
            Move(-(${width_zenkaku} / 2 - ${width_hankaku} / 2), 0)
        endif
        SetWidth(${width_hankaku})
        glyphName = GlyphInfo("Name")
        Select(orig[j])
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
    endloop

    orig = [0u25a0, 0u25a1,\
            0u25b2, 0u25b3,\
            0u25b6, 0u25b7,\
            0u25bc, 0u25bd,\
            0u25c0, 0u25c1,\
            0u25c6, 0u25c7,\
            0u25cb,\
            0u25ce, 0u25cf,\
            0u2605, 0u2606\
            ] # ■□ ▲△ ▶▷ ▼▽ ◀◁ ◆◇ ○ ◎● ★☆
    j = 0
    while (j < SizeOf(orig))
        Select(orig[j]); Copy()
        Select(k); Paste()
        if (600 <= GlyphInfo("Width"))
            Scale(${scale_zenkaku2hankaku} * ${width_hankaku} / ${width_hankaku_loose}, ${width_zenkaku} / 2, 340)
            Move(-(${width_zenkaku} / 2 - ${width_hankaku} / 2), 0)
        endif
        SetWidth(${width_hankaku})
        glyphName = GlyphInfo("Name")
        Select(orig[j])
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
    endloop

    j = 0
    while (j < 8)
        Select(0u2660 + j); Copy() # ♠-♧
        Select(k); Paste()
        if (600 <= GlyphInfo("Width"))
            Scale(${scale_zenkaku2hankaku} * ${width_hankaku} / ${width_hankaku_loose} * 1.1, 100, ${width_zenkaku} / 2, 0)
            Move(-(${width_zenkaku} / 2 - ${width_hankaku} / 2), 0)
        endif
        SetWidth(${width_hankaku})
        glyphName = GlyphInfo("Name")
        Select(0u2660 + j)
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
    endloop

    j = 0
    while (j < 7)
        Select(0u2669 + j); Copy() # ♩-♯
        Select(k); Paste()
        if (600 <= GlyphInfo("Width"))
            Scale(${scale_zenkaku2hankaku} * ${width_hankaku} / ${width_hankaku_loose} * 1.2, 100, ${width_zenkaku} / 2, 0)
            Move(-(${width_zenkaku} / 2 - ${width_hankaku} / 2), 0)
        endif
        SetWidth(${width_hankaku})
        glyphName = GlyphInfo("Name")
        Select(0u2669 + j)
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
    endloop

    j = 0
    while (j < 10)
        Select(0u2776 + j); Copy() # ❶-❿
        Select(k); Paste()
        if (600 <= GlyphInfo("Width"))
            Scale(${scale_zenkaku2hankaku} * ${width_hankaku} / ${width_hankaku_loose} * 0.95, 100, ${width_zenkaku} / 2, 0)
            Move(-(${width_zenkaku} / 2 - ${width_hankaku} / 2), 0)
        endif
        SetWidth(${width_hankaku})
        glyphName = GlyphInfo("Name")
        Select(0u2776 + j)
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
    endloop

    ss += 1

 # 一旦削除した subs を追加
 #    Print("Add subs lookups")
 #    Select(0u0061) # a
 #    lookups = GetPosSub("*") # フィーチャを取り出す
 #
 #    orig = [0u03b2, 0u03b3, 0u03c1, 0u03c6, 0u03c7, 0u0259] # βγρφχə
 #    subs = [0u1d66, 0u1d67, 0u1d68, 0u1d69, 0u1d6a, 0u2094] # ᵦᵧᵨᵩᵪₔ
 #    j = 0
 #    while (j < SizeOf(orig))
 #        Select(subs[j])
 #        Move(0, ${move_y_sub_base}) # latin フォントに高さを合わせる
 #        SetWidth(${width_hankaku})
 #        glyphName = GlyphInfo("Name")
 #        Select(orig[j])
 #        AddPosSub(lookups[2][0],glyphName)
 #        j += 1
 #    endloop

# 一旦削除した sups を追加
    Print("Add sups lookups")
    Select(0u00c6) # Æ
    lookups = GetPosSub("*") # フィーチャを取り出す

 #    orig = [0u03b2, 0u03b3, 0u03b4, 0u03c6, 0u03c7, 0u0259] # βγδφχə
 #    sups = [0u1d5d, 0u1d5e, 0u1d5f, 0u1d60, 0u1d61, 0u1d4a] # ᵝᵞᵟᵠᵡᵊ
 #    j = 0
 #    while (j < SizeOf(orig))
 #        Select(sups[j])
 #        Move(0, ${move_y_super_base}) # latin フォントに高さを合わせる
 #        SetWidth(${width_hankaku})
 #        glyphName = GlyphInfo("Name")
 #        Select(orig[j])
 #        AddPosSub(lookups[0][0],glyphName)
 #        j += 1
 #    endloop

 #    orig = [0u00c6, 0u00f0, 0u018e, 0u014b,\
 #            0u03b8] # ÆðƎŋ θ
 #    sups = [0u1d2d, 0u1d9e, 0u1d32, 0u1d51,\
 #            0u1dbf] # ᴭᶞᴲᵑ ᶿ
 #    j = 0
 #    while (j < SizeOf(orig))
 #        Select(sups[j])
 #        Move(0, ${move_y_super_base}) # latin フォントに高さを合わせる
 #        SetWidth(${width_hankaku})
 #        glyphName = GlyphInfo("Name")
 #        Select(orig[j])
 #        AddPosSub(lookups[0][0],glyphName)
 #        j += 1
 #    endloop

 #    orig = [0u043d] # н
 #    sups = [0u1d78] # ᵸ
 #    j = 0
 #    while (j < SizeOf(orig))
 #        Select(sups[j])
 #        Move(0, ${move_y_super_base}) # latin フォントに高さを合わせる
 #        SetWidth(${width_hankaku})
 #        glyphName = GlyphInfo("Name")
 #        Select(orig[j])
 #        AddPosSub(lookups[0][0],glyphName)
 #        j += 1
 #    endloop

    orig = [0u0269] # ɩ
    sups = [0u1da5] # ᶥ
 #    orig = [0u0250, 0u0251, 0u0252, 0u0254,\
 #            0u0255, 0u025b, 0u025c, 0u025f,\
 #            0u0261, 0u0265, 0u0268, 0u0269,\
 #            0u026a, 0u026d, 0u026f, 0u0270,\
 #            0u0271, 0u0272, 0u0273, 0u0274,\
 #            0u0275, 0u0278, 0u0282, 0u0283,\
 #            0u0289, 0u028a, 0u028b, 0u028c,\
 #            0u0290, 0u0291, 0u0292, 0u029d,\
 #            0u029f, 0u0266, 0u0279, 0u027b,\
 #            0u0281, 0u0294, 0u0295, 0u0263]
 #            # ɐɑɒɔ ɕɛɜɟ ɡɥɨɩ ɪɭɯɰ ɱɲɳɴ ɵɸʂʃ ʉʊʋʌ ʐʑʒʝ ʟɦɹɻ ʁʔʕɣ
 #    sups = [0u1d44, 0u1d45, 0u1d9b, 0u1d53,\
 #            0u1d9d, 0u1d4b, 0u1d9f, 0u1da1,\
 #            0u1da2, 0u1da3, 0u1da4, 0u1da5,\
 #            0u1da6, 0u1da9, 0u1d5a, 0u1dad,\
 #            0u1dac, 0u1dae, 0u1daf, 0u1db0,\
 #            0u1db1, 0u1db2, 0u1db3, 0u1db4,\
 #            0u1db6, 0u1db7, 0u1db9, 0u1dba,\
 #            0u1dbc, 0u1dbd, 0u1dbe, 0u1da8,\
 #            0u1dab, 0u02b1, 0u02b4, 0u02b5,\
 #            0u02b6, 0u02c0, 0u02c1, 0u02e0]
 #            # ᵄᵅᶛᵓ ᶝᵋᶟᶡ ᶢᶣᶤᶥ ᶦᶩᵚᶭ ᶬᶮᶯᶰ ᶱᶲᶳᶴ ᶶᶷᶹᶺ ᶼᶽᶾᶨ ᶫʱʴʵ ʶˀˁˠ
    j = 0
    while (j < SizeOf(orig))
        Select(sups[j])
        Move(0, ${move_y_super_base}) # latin フォントに高さを合わせる
        SetWidth(${width_hankaku})
        glyphName = GlyphInfo("Name")
        Select(orig[j])
        AddPosSub(lookups[0][0],glyphName)
        j += 1
    endloop

 #    orig = [0u1d16, 0u1d17, 0u1d1d, 0u1d7b,\
 #            0u1d85, 0u01ab] # ᴖᴗᴝᵻ ᶅƫ
 #    sups = [0u1d54, 0u1d55, 0u1d59, 0u1da7,\
 #            0u1daa, 0u1db5] # ᵔᵕᵙᶧ ᶪᶵ
 #    j = 0
 #    while (j < SizeOf(orig))
 #        Select(sups[j])
 #        Move(0, ${move_y_super_base}) # latin フォントに高さを合わせる
 #        SetWidth(${width_hankaku})
 #        glyphName = GlyphInfo("Name")
 #        Select(orig[j])
 #        AddPosSub(lookups[0][0],glyphName)
 #        j += 1
 #    endloop

    sups = [0u1d3b, 0u1d46, 0u1d4c, 0u1d4e] # ᴻᵆᵌᵎ # 基本のグリフ無し、上付きのみ
 #    sups = [0u1d3b, 0u1d46, 0u1d4c, 0u1d4e, 0u02e4] # ᴻᵆᵌᵎˤ # 基本のグリフ無し、上付きのみ
    j = 0
    while (j < SizeOf(sups))
        Select(sups[j])
        Move(0, ${move_y_super_base}) # latin フォントに高さを合わせる
        SetWidth(${width_hankaku})
        j += 1
    endloop

# aalt 対応
    Print("Add aalt lookups")
# aalt 1対1
    Select(0u342e) # 㐮
    lookups = GetPosSub("*") # フィーチャを取り出す

    orig = [0u0041, 0u0042, 0u0044, 0u0045,\
            0u0047, 0u0048, 0u0049, 0u004a,\
            0u004b, 0u004c, 0u004d, 0u004e,\
            0u004f, 0u0050, 0u0052, 0u0054,\
            0u0055, 0u0056, 0u0057] # ABDE GHIJ KLMN OPRT UVW
    supb = [0u1d2c, 0u1d2e, 0u1d30, 0u1d31,\
            0u1d33, 0u1d34, 0u1d35, 0u1d36,\
            0u1d37, 0u1d38, 0u1d39, 0u1d3a,\
            0u1d3c, 0u1d3e, 0u1d3f, 0u1d40,\
            0u1d41, 0u2c7d, 0u1d42] # ᴬᴮᴰᴱ ᴳᴴᴵᴶ ᴷᴸᴹᴺ ᴼᴾᴿᵀ ᵁⱽᵂ
    j = 0
    while (j < SizeOf(orig))
        Select(supb[j])
        glyphName = GlyphInfo("Name")
        Select(orig[j])
        AddPosSub(lookups[0][0],glyphName)
        j += 1
    endloop

    orig = [0u0062, 0u0063, 0u0064, 0u0066,\
            0u0067, 0u0077, 0u0079, 0u007a] # bcdf gwyz
    supb = [0u1d47, 0u1d9c, 0u1d48, 0u1da0,\
            0u1d4d, 0u02b7, 0u02b8, 0u1dbb] # ᵇᶜᵈᶠ ᵍʷʸᶻ
    j = 0
    while (j < SizeOf(orig))
        Select(supb[j])
        glyphName = GlyphInfo("Name")
        Select(orig[j])
        AddPosSub(lookups[0][0],glyphName)
        j += 1
    endloop

    orig = [0u00c6, 0u00f0, 0u018e, 0u014b,\
            0u03b4, 0u03b8, 0u03c1] # ÆðƎŋ δθρ
    supb = [0u1d2d, 0u1d9e, 0u1d32, 0u1d51,\
            0u1d5f, 0u1dbf, 0u1d68] # ᴭᶞᴲᵑ ᵟᶿᵨ

    j = 0
    while (j < SizeOf(orig))
        Select(supb[j])
        glyphName = GlyphInfo("Name")
        Select(orig[j])
        AddPosSub(lookups[0][0],glyphName)
        j += 1
    endloop

    orig = [0u043d] # н
    supb = [0u1d78] # ᵸ
    j = 0
    while (j < SizeOf(orig))
        Select(supb[j])
        glyphName = GlyphInfo("Name")
        Select(orig[j])
        AddPosSub(lookups[0][0],glyphName)
        j += 1
    endloop

    orig = [0u0250, 0u0251, 0u0252, 0u0254,\
            0u0255, 0u025b, 0u025c, 0u025f,\
            0u0261, 0u0265, 0u0268, 0u0269,\
            0u026a, 0u026d, 0u026f, 0u0270,\
            0u0271, 0u0272, 0u0273, 0u0274,\
            0u0275, 0u0278, 0u0282, 0u0283,\
            0u0289, 0u028a, 0u028b, 0u028c,\
            0u0290, 0u0291, 0u0292, 0u029d,\
            0u029f, 0u0266, 0u0279, 0u027b,\
            0u0281, 0u0294, 0u0295, 0u0263]
            # ɐɑɒɔ ɕɛɜɟ ɡɥɨɩ ɪɭɯɰ ɱɲɳɴ ɵɸʂʃ ʉʊʋʌ ʐʑʒʝ ʟɦɹɻ ʁʔʕɣ
    supb = [0u1d44, 0u1d45, 0u1d9b, 0u1d53,\
            0u1d9d, 0u1d4b, 0u1d9f, 0u1da1,\
            0u1da2, 0u1da3, 0u1da4, 0u1da5,\
            0u1da6, 0u1da9, 0u1d5a, 0u1dad,\
            0u1dac, 0u1dae, 0u1daf, 0u1db0,\
            0u1db1, 0u1db2, 0u1db3, 0u1db4,\
            0u1db6, 0u1db7, 0u1db9, 0u1dba,\
            0u1dbc, 0u1dbd, 0u1dbe, 0u1da8,\
            0u1dab, 0u02b1, 0u02b4, 0u02b5,\
            0u02b6, 0u02c0, 0u02c1, 0u02e0]
            # ᵄᵅᶛᵓ ᶝᵋᶟᶡ ᶢᶣᶤᶥ ᶦᶩᵚᶭ ᶬᶮᶯᶰ ᶱᶲᶳᶴ ᶶᶷᶹᶺ ᶼᶽᶾᶨ ᶫʱʴʵ ʶˀˁˠ
    j = 0
    while (j < SizeOf(orig))
        Select(supb[j])
        glyphName = GlyphInfo("Name")
        Select(orig[j])
        AddPosSub(lookups[0][0],glyphName)
        j += 1
    endloop

 #    orig = [0u1d16, 0u1d17, 0u1d1d, 0u1d7b,\
 #            0u1d85, 0u01ab] # ᴖᴗᴝᵻ ᶅƫ
 #    supb = [0u1d54, 0u1d55, 0u1d59, 0u1da7,\
 #            0u1daa, 0u1db5] # ᵔᵕᵙᶧ ᶪᶵ
 #    j = 0
 #    while (j < SizeOf(orig))
 #        Select(supb[j])
 #        glyphName = GlyphInfo("Name")
 #        Select(orig[j])
 #        AddPosSub(lookups[0][0],glyphName)
 #        j += 1
 #    endloop

# aalt 複数
    Select(0u3402) # 㐂
    lookups = GetPosSub("*") # フィーチャを取り出す

    orig = [0u0030, 0u0031, 0u0032, 0u0033,\
            0u0034, 0u0035, 0u0036, 0u0037,\
            0u0038, 0u0039,\
            0u002b, 0u002d, 0u003d, 0u0028, 0u0029] # 0-9,+-=()
    sups = [0u2070, 0u00b9, 0u00b2, 0u00b3,\
            0u2074, 0u2075, 0u2076, 0u2077,\
            0u2078, 0u2079,\
            0u207a, 0u207b, 0u207c, 0u207d, 0u207e] # ⁰-⁹,⁺⁻⁼⁽⁾
    subs = [0u2080, 0u2081, 0u2082, 0u2083,\
            0u2084, 0u2085, 0u2086, 0u2087,\
            0u2088, 0u2089,\
            0u208a, 0u208b, 0u208c, 0u208d, 0u208e] # ₀-₉,₊₋₌₍₎
    j = 0
    while (j < SizeOf(orig))
        Select(sups[j])
        glyphName = GlyphInfo("Name")
        Select(orig[j])
        AddPosSub(lookups[0][0],glyphName)
        Select(subs[j])
        glyphName = GlyphInfo("Name")
        Select(orig[j])
        AddPosSub(lookups[0][0],glyphName)
        j += 1
    endloop

    orig = [0u0061, 0u0065, 0u0068, 0u0069,\
            0u006a, 0u006b, 0u006c, 0u006d,\
            0u006e, 0u006f, 0u0070, 0u0072,\
            0u0073, 0u0074, 0u0075, 0u0076,\
            0u0078] # aehi jklm nopr stuv x
    sups = [0u1d43, 0u1d49, 0u02b0, 0u2071,\
            0u02b2, 0u1d4f, 0u02e1, 0u1d50,\
            0u207f, 0u1d52, 0u1d56, 0u02b3,\
            0u02e2, 0u1d57, 0u1d58, 0u1d5b,\
            0u02e3] # ᵃᵉʰⁱ ʲᵏˡᵐ ⁿᵒᵖʳ ˢᵗᵘᵛ ˣ
    subs = [0u2090, 0u2091, 0u2095, 0u1d62,\
            0u2c7c, 0u2096, 0u2097, 0u2098,\
            0u2099, 0u2092, 0u209a, 0u1d63,\
            0u209b, 0u209c, 0u1d64, 0u1d65,\
            0u2093] # ₐₑₕᵢ ⱼₖₗₘ ₙₒₚᵣ ₛₜᵤᵥ ₓ
    j = 0
    while (j < SizeOf(orig))
        Select(sups[j])
        glyphName = GlyphInfo("Name")
        Select(orig[j])
        AddPosSub(lookups[0][0],glyphName)
        Select(subs[j])
        glyphName = GlyphInfo("Name")
        Select(orig[j])
        AddPosSub(lookups[0][0],glyphName)
        j += 1
    endloop

    orig = [0u0061, 0u006f] # ao
    sups = [0u00aa, 0u00ba] # ªº
    j = 0
    while (j < SizeOf(orig))
        Select(sups[j])
        glyphName = GlyphInfo("Name")
        Select(orig[j])
        AddPosSub(lookups[0][0],glyphName)
        j += 1
    endloop

    orig = [0u03b2, 0u03b3, 0u03c6, 0u03c7, 0u0259] # βγφχə
    sups = [0u1d5d, 0u1d5e, 0u1d60, 0u1d61, 0u1d4a] # ᵝᵞᵠᵡᵊ
    subs = [0u1d66, 0u1d67, 0u1d69, 0u1d6a, 0u2094] # ᵦᵧᵩᵪₔ

    j = 0
    while (j < SizeOf(orig))
        Select(sups[j])
        glyphName = GlyphInfo("Name")
        Select(orig[j])
        AddPosSub(lookups[0][0],glyphName)
        Select(subs[j])
        glyphName = GlyphInfo("Name")
        Select(orig[j])
        AddPosSub(lookups[0][0],glyphName)
        j += 1
    endloop

    Print("Add aalt nalt lookups")
# aalt nalt 1対1
    Select(0u4e2d) # 中
    lookups = GetPosSub("*") # フィーチャを取り出す

    Select(0u00a9) # ©
    glyphName = GlyphInfo("Name")
    Select(0u0043) # C
    AddPosSub(lookups[0][0],glyphName)
    AddPosSub(lookups[1][0],glyphName)

    Select(0u2117) # ℗
    glyphName = GlyphInfo("Name")
    Select(0u0050) # P
    AddPosSub(lookups[0][0],glyphName)
    AddPosSub(lookups[1][0],glyphName)

    Select(0u00ae) # ®
    glyphName = GlyphInfo("Name")
    Select(0u0052) # R
    AddPosSub(lookups[0][0],glyphName)
    AddPosSub(lookups[1][0],glyphName)

# --------------------------------------------------

# Proccess before saving
    Print("Process before saving")
    SelectWorthOutputting()
    SetGlyphClass("automatic")

# --------------------------------------------------

# Save modified font
    Print("Save " + input_ttf)
    Generate(input_ttf, "", 0x04)
 #    Generate(input_ttf, "", 0x84)
    Close()
    Print("")

    i += 1
endloop

Quit()
_EOT_

################################################################################
# Generate script to convert to oblique style
################################################################################

cat > ${tmpdir}/${oblique_converter} << _EOT_
#!$fontforge_command -script

usage = "Usage: ${oblique_converter} fontfamily-fontstyle.ttf ..."

# Get arguments
if (\$argc == 1)
    Print(usage)
    Quit()
endif

Print("- Generate oblique style fonts -")

# Begin loop
i = 1
while (i < \$argc)

# Check filename
    input_ttf = \$argv[i]
    input     = input_ttf:t:r
    if (input_ttf:t:e != "ttf")
        Print(usage)
        Quit()
    endif

    hypen_index = Strrstr(input, '-')
    if (hypen_index == -1)
        Print(usage)
        Quit()
    endif

# Get parameters
    input_family = Strsub(input, 0, hypen_index)
    input_style  = Strsub(input, hypen_index + 1)

    output_family = input_family

    if (input_style == "Regular" || input_style == "Roman")
        output_style = "Oblique"
        style        = "Oblique"
    else
        output_style = input_style + "Oblique"
        style        = input_style + " Oblique"
    endif

# Open file and set configuration
    Print("Open " + input_ttf)
    Open(input_ttf)

    Reencode("unicode")

    SetFontNames(output_family + "-" + output_style, \
                 \$familyname, \
                 \$familyname + " " + style, \
                 style)
    SetTTFName(0x409, 2, style)
    SetTTFName(0x409, 3, "FontForge ${fontforge_version} : " + "FontTools ${ttx_version} : " + \$fullname + " : " + Strftime("%d-%m-%Y", 0))

# --------------------------------------------------

# Transform
    Print("Transform glyphs (it may take a few minutes)")
    SelectWorthOutputting()
    SelectFewer(0u0020) # 半角スペース
    SelectFewer(0u00a0) # ノーブレークスペース
# SelectFewer(0u2000, 0u2140) # 文字様記号
    SelectFewer(0u2102) # ℂ
    SelectFewer(0u210d) # ℍ
    SelectFewer(0u2115) # ℕ
    SelectFewer(0u2119) # ℙ
    SelectFewer(0u211a) # ℚ
    SelectFewer(0u211d) # ℝ
    SelectFewer(0u2124) # ℤ
    SelectFewer(0u212e) # ℮
    SelectFewer(0u213c, 0u2140) # ℼℽℾℿ⅀
    SelectFewer(0u2145, 0u2149) # ⅅⅆⅇⅈⅉ
# SelectFewer(0u2190, 0u21ff) # 矢印
    SelectFewer(0u2191) # ↑
    SelectFewer(0u2193) # ↓
    SelectFewer(0u2195, 0u2199) # ↕↖↗↘↙
    SelectFewer(0u219f) # ↟
    SelectFewer(0u21a1) # ↡
    SelectFewer(0u21a5) # ↥
    SelectFewer(0u21a7, 0u21a8) # ↧↨
    SelectFewer(0u21b8) # ↸
    SelectFewer(0u21be, 0u21bf) # ↾↿
    SelectFewer(0u21c2, 0u21c3) # ⇂⇃
    SelectFewer(0u21c5) # ⇅
    SelectFewer(0u21c8) # ⇈
    SelectFewer(0u21ca) # ⇊
    SelectFewer(0u21d1) # ⇑
    SelectFewer(0u21d3) # ⇓
    SelectFewer(0u21d5, 0u21d9) # ⇕⇖⇗⇘⇙
    SelectFewer(0u21de, 0u21df) # ⇞⇟
    SelectFewer(0u21e1) # ⇡
    SelectFewer(0u21e3) # ⇣
    SelectFewer(0u21e7) # ⇧
    SelectFewer(0u21e9, 0u21ef) # ⇩⇪⇫⇬⇭⇮⇯
    SelectFewer(0u21f1, 0u21f3) # ⇱⇲⇳
    SelectFewer(0u21f5) # ⇵
# SelectFewer(0u2200, 0u22ff) # 数学記号
    SelectFewer(0u221f, 0u2222) # ∟∠∡∢
    SelectFewer(0u2225, 0u2226) # ∥∦
 #    SelectFewer(0u2295, 0u22a1) # ⊕ - ⊡
    SelectFewer(0u22a2, 0u22a5) # ⊢ - ⊥
 #    SelectFewer(0u22a6, 0u22af) # ⊦ - ⊯
 #    SelectFewer(0u22b6, 0u22b8) # ⊶ - ⊸
    SelectFewer(0u22be, 0u22bf) # ⊾⊿
 #    SelectFewer(0u22c8, 0u22cc) # ⋈⋉⋊⋋⋌
 #    SelectFewer(0u22ee, 0u22f1) # ⋮⋯⋰⋱
# SelectFewer(0u2300, 0u23ff) # その他の技術用記号
    SelectFewer(0u2300, 0u2307) # ⌀ - ⌇
    SelectFewer(0u230c, 0u230f) # ⌌ - ⌏
    SelectFewer(0u2311, 0u2318) # ⌑ - ⌘
    SelectFewer(0u231c, 0u231f) # ⌜ - ⌟
    SelectFewer(0u231a, 0u231b) # ⌚⌛
    SelectFewer(0u2320, 0u2328) # ⌠ - ⌨
    SelectFewer(0u232b, 0u23ff) # ⌫ - ⏿
# SelectFewer(0u2400, 0u243f) # 制御機能用記号
 #      SelectFewer(0u2423) # ␣
    SelectFewer(0u2425) # ␥
    SelectFewer(0u2440, 0u245f) # 光学的文字認識、OCR
    SelectFewer(0u2500, 0u259f) # 罫線素片・ブロック要素
# SelectFewer(0u25a0, 0u25ff) # 幾何学模様
    SelectFewer(0u25a0, 0u25db) # ■ - ◛
    SelectFewer(0u25dc, 0u25df) # ◜ - ◟
    SelectFewer(0u25e0, 0u25ff) # ◠ - ◿
    SelectFewer(0u2600, 0u26ff) # その他の記号
# SelectFewer(0u2700, 0u27bf) # 装飾記号
    SelectFewer(0u2700, 0u2752) # ✀ - ❒
    SelectFewer(0u2756) # ❖
    SelectFewer(0u2758, 0u275a) # ❘ - ❚
 #    SelectFewer(0u2761, 0u2763) # ❡ - ❣
    SelectFewer(0u2764, 0u2767) # ❤ - ❧
    SelectFewer(0u2795, 0u2798) # ➕ - ➘
    SelectFewer(0u279a) # ➚
    SelectFewer(0u27b0) # ➰
    SelectFewer(0u27b2) # ➲
    SelectFewer(0u27b4) # ➴
    SelectFewer(0u27b6, 0u27b7) # ➶➷
    SelectFewer(0u27b9) # ➹
    SelectFewer(0u27bf) # ➿
# SelectFewer(0u27c0, 0u27ef) # その他の数学記号 A
    SelectFewer(0u27c0) # ⟀
 #    SelectFewer(0u27c1) # ⟁
    SelectFewer(0u27c2) # ⟂
 #    SelectFewer(0u27d3, 0u27e5) # ⟓ - ⟥
# SelectFewer(0u27f0, 0u27ff) # 補助矢印 A
    SelectFewer(0u27f0, 0u27f1) # ⟰⟱
    SelectFewer(0u2800, 0u28ff) # 点字
# SelectFewer(0u2900, 0u2970) # 補助矢印 B
    SelectFewer(0u2908, 0u290b) # ⤈⤉⤊⤋
    SelectFewer(0u2912, 0u2913) # ⤒⤓
    SelectFewer(0u2921, 0u2932) # ⤡ - ⤲
    SelectFewer(0u2949) # ⥉
    SelectFewer(0u294c, 0u294d) # ⥌⥍
    SelectFewer(0u294f) # ⥏
    SelectFewer(0u2951) # ⥑
    SelectFewer(0u2954, 0u2955) # ⥔⥕
    SelectFewer(0u2958, 0u2959) # ⥘⥙
    SelectFewer(0u295c, 0u295d) # ⥜⥝
    SelectFewer(0u2960, 0u2961) # ⥠⥡
    SelectFewer(0u2963) # ⥣
    SelectFewer(0u2965) # ⥥
    SelectFewer(0u296e, 0u296f) # ⥮⥯
    SelectFewer(0u297e, 0u297f) # ⥾⥿
# SelectFewer(0u2980, 0u29ff) # その他の数学記号 B
    SelectFewer(0u299b, 0u29af) # ⦛ - ⦯
 #    SelectFewer(0u29b0, 0u29d7) # ⦰ - ⧗
 #    SelectFewer(0u29df, 0u29f3) # ⧟ - ⧳
# SelectFewer(0u2a00, 0u2aff) # 補助数学記号
 #    SelectFewer(0u2a00, 0u2a02) # ⨀⨁⨂
 #    SelectFewer(0u2a36, 0u2a3b) # ⨶⨷⨸⨹⨺⨻
 #    SelectFewer(0u2ade, 0u2af1) # ⫞ - ⫱
# SelectFewer(0u2b00, 0u2bff) # その他の記号および矢印
    SelectFewer(0u2b00, 0u2b03) # ⬀⬁⬂⬃
    SelectFewer(0u2b06, 0u2b0b) # ⬆⬇⬈⬉⬊⬋
    SelectFewer(0u2b0d) # ⬍
    SelectFewer(0u2b12, 0u2b2f) # ⬒ - ⬯
    SelectFewer(0u2b4e, 0u2b5f) # ⭎ - ⭟
    SelectFewer(0u2b61) # ⭡
    SelectFewer(0u2b63) # ⭣
    SelectFewer(0u2b65, 0u2b69) # ⭥⭦⭧⭨⭩
    SelectFewer(0u2b6b) # ⭫
    SelectFewer(0u2b6d) # ⭭
    SelectFewer(0u2b71) # ⭱
    SelectFewer(0u2b73) # ⭳
    SelectFewer(0u2b76, 0u2b79) # ⭶⭷⭸⭹
    SelectFewer(0u2b7b) # ⭻
    SelectFewer(0u2b7d) # ⭽
    SelectFewer(0u2b7f) # ⭿
    SelectFewer(0u2b81) # ⮁
    SelectFewer(0u2b83) # ⮃
    SelectFewer(0u2b85) # ⮅
    SelectFewer(0u2b87, 0u2b8b) # ⮇⮈⮉⮊⮋
    SelectFewer(0u2b97) # ⮗
    SelectFewer(0u2b99) # ⮙
    SelectFewer(0u2b9b) # ⮛
    SelectFewer(0u2b9d) # ⮝
    SelectFewer(0u2b9f) # ⮟
    SelectFewer(0u2bb8, 0u2bff) # ⮸ - ⯿
    SelectFewer(0u2ff0, 0u2fff) # 漢字構成記述文字
    SelectFewer(0u3000) # 全角スペース
    SelectFewer(0u3004) # 〄
 #    SelectFewer(0u3012) # 〒
    SelectFewer(0u3013) # 〓
    SelectFewer(0u3020) # 〠
 #    SelectFewer(0u3036) # 〶
    SelectFewer(0u31ef) # ㇯
    SelectFewer(0ufe17, 0ufe18) # 縦書き用括弧
    SelectFewer(0ufe19) # ︙
    SelectFewer(0ufe30, 0ufe34) # ︰︱︲︳︴
    SelectFewer(0ufe35, 0ufe44) # 縦書き用括弧
    SelectFewer(0ufe47, 0ufe48) # 縦書き用括弧
 #    SelectFewer(0u1d538, 0u1d539) # 𝔸𝔹
 #    SelectFewer(0u1d53b, 0u1d53e) # 𝔻𝔼𝔽𝔾
 #    SelectFewer(0u1d540, 0u1d544) # 𝕀𝕁𝕂𝕃𝕄
 #    SelectFewer(0u1d546) # 𝕆
 #    SelectFewer(0u1d54a, 0u1d550) # 𝕊𝕋𝕌𝕍𝕎𝕏𝕐
 #    SelectFewer(0u1d552, 0u1d56b) # 𝕒-𝕫
    SelectFewer(0u1f310) # 🌐
    SelectFewer(0u1f3a4) # 🎤
    SelectFewer(0u1f3b5, 0u1f3b6) # 🎵🎶
    SelectFewer(0u1f4a9)        # 💩
    SelectFewer(0u1f512)        # 🔒
    SelectFewer(0u1f916)        # 🤖
    SelectFewer("uniFFFD") # Replacement Character
    SelectFewer(".notdef") # notdef
    if ("${nerd_flag}" == "true")
        SelectFewer(0ue000, 0uf8ff) # NerdFonts
        SelectFewer(0uf0001, 0uf1af0) # NerdFonts
        if ("${liga_flag}" == "true")
            SelectMore(0ue100, 0ue129) # リガチャは斜体にする
        endif
    endif

    SelectFewer(${address_store_underline}, ${address_store_underline} + 2) # 保管した下線
    SelectFewer(${address_store_braille}, ${address_store_braille} + 255) # 保管した点字
    SelectFewer(${address_store_line}, ${address_store_line} + 31) # 保管した罫線
    SelectFewer(${address_store_visi_kana} + 3) # 保管した︲
    SelectFewer(${address_store_visi_kana} + 5) # 保管した︱
    SelectFewer(${address_store_arrow}, ${address_store_arrow} + 3) # 保管した矢印
    SelectFewer(${address_store_vert}, ${address_store_vert} + 1) # 保管した縦書きの縦線無し（）
    SelectFewer(${address_store_vert} + 4, ${address_store_vert} + 19) # 保管した縦書きの縦線無し： - ｠
    SelectFewer(${address_store_vert} + 22, ${address_store_vert} + 23) # 保管した縦書きの縦線無し／＼
    SelectFewer(${address_store_vert} + 102) # 保管した縦書きの縦線無し￤
    SelectFewer(${address_store_d_hyphen}) # 保管した縦書きの゠
    SelectFewer(${address_store_otherspace}, ${address_store_otherspace} + 1) # 保管したその他のスペース

    SelectFewer("uni3008.vert", "uni301F.vert") # 縦書きの括弧、〓
    SelectFewer("uni30FC.vert") # 縦書きのー
    SelectFewer("uniFFE4.vert") # 縦書きの￤
    SelectFewer("uni2702.vert", "uni30A0.vert") # 縦書きの✂‖〰゠

    SelectFewer("uni3000.ss01") # ss01の全角スペース

    SelectFewer("space.ss02") # ss02の半角スペース
    SelectFewer("uni00A0.ss02") # ss02のノーブレークスペース

    SelectFewer("uniFF08.vert.ss06", "uniFF09.vert.ss06") # ss06の縦書きの（）
    SelectFewer("uniFF1A.vert.ss06", "uniFF60.vert.ss06") # ss06の縦書きの： - ｠
    SelectFewer("uniFF0F.vert.ss06", "uniFF3C.vert.ss06") # ss06の縦書きの／＼
    SelectFewer("uniFFE4.vert.ss06") # ss06の縦書きの￤
    SelectFewer("uni2800.ss06", "uni28FF.ss06") # ss06の点字

    SelectFewer("uniFE32.ss07") # ss07の︲
    SelectFewer("uniFE31.ss07") # ss07の︱
    SelectFewer("uni30A0.vert.ss07") # ss07の縦書きの゠

    SelectFewer("SF100000.ss09", "arrowdown.ss09") # ss09の罫線、矢印

    SelectFewer("uni2001.ss11") # ss11の全角スペース
    SelectFewer("uni034F.ss11") # ss11の半角スペース

    SelectFewer("arrowup.ss12") # ss12の↑
    SelectFewer("arrowdown.ss12") # ss12の↓
    SelectFewer("arrowupdn.ss12") # ss12の↕
    SelectFewer("arrowdblup.ss12") # ss12の⇑
    SelectFewer("arrowdbldown.ss12") # ss12の⇓
    SelectFewer("uni21D5.ss12") # ss12の⇕
    SelectFewer("filledbox.ss12", "uni266F.ss12") # ss12の■-♯

    Transform(100, 0, ${tan_oblique}, 100, ${move_x_oblique}, 0)
    RemoveOverlap()
    RoundToInt()

# 半角・全角形、縦書き用を作り直し
    Print("Edit hankaku kana, zenkaku eisuu and vert glyphs")

    j = 0
    while (j < ${num_mod_glyphs})
        Select(${address_store_mod} + ${num_mod_glyphs} * 1 + j); Copy() # 保管した横書きのＤＱＶＺ
        Select(${address_store_mod} + ${num_mod_glyphs} * 4 + j); Paste() # 保管した下線ありの横書きのＤＱＶＺ
        Select(${address_store_underline}); Copy() # 下線追加
        Select(${address_store_mod} + ${num_mod_glyphs} * 4 + j); PasteInto() # 保管した下線ありの横書きのＤＱＶＺ
        SetWidth(${width_zenkaku})

        Select(${address_store_mod} + ${num_mod_glyphs} * 2 + j); Copy() # 保管した縦書きのＤＱＶＺ
        Select(${address_store_mod} + ${num_mod_glyphs} * 5 + j); Paste() # 保管した縦線ありの縦書きのＤＱＶＺ
        Select(${address_store_underline} + 2); Copy() # 縦線追加
        Select(${address_store_mod} + ${num_mod_glyphs} * 5 + j); PasteInto() # 保管した縦線ありの縦書きのＤＱＶＺ
        SetWidth(${width_zenkaku})
        j += 1
    endloop

    Select(${address_store_zero} + 3); Copy() # 保管した全角のスラッシュ無し０
    Select(${address_store_zero} + 4); Paste() # 保管した横書きのスラッシュ無し０
    Select(${address_store_underline}); Copy() # 下線追加
    Select(${address_store_zero} + 4); PasteInto() # 保管した横書きのスラッシュ無し０
    SetWidth(${width_zenkaku})

    Select(${address_store_zero} + 3); Copy() # 保管した全角のスラッシュ無し０
    Select(${address_store_zero} + 5); Paste() # 保管した縦書きのスラッシュ無し０
    Select(${address_store_underline} + 2); Copy() # 縦線追加
    Select(${address_store_zero} + 5); PasteInto() # 保管した縦書きのスラッシュ無し０
    SetWidth(${width_zenkaku})

    Select("uniFF08.vert")
    vert = GlyphInfo("Encoding")
    Select("uni2702.vert")
    vert2 = GlyphInfo("Encoding")
    j = 0
    while (j < vert2 - vert)
        Select(${address_store_vert} + j); Copy() # 保管した縦線無し縦書き
        Select(vert + j); Paste() # 縦書き
        Select(${address_store_underline} + 2); Copy() # 縦線追加
        Select(vert + j); PasteInto() # 縦書き
        SetWidth(${width_zenkaku})
        j += 1
    endloop

    Select("uniFF24.ss08")
    ss = GlyphInfo("Encoding")
    st = [35, 48, 53, 57] # 保管した全角半角文字の頭からＤＱＶＺまでの数
    j = 0
    while (j < SizeOf(st))
        Select(${address_store_zenhan} + st[j]); Copy() # 保管した横書きのＤＱＶＺ
        Select(ss + j); Paste() # 横書きのss08用ＤＱＶＺ
        Select(${address_store_underline}); Copy() # 下線追加
        Select(ss + j); PasteInto() # 横書きのss08用ＤＱＶＺ
        SetWidth(${width_zenkaku})
        j += 1
    endloop

    Select("uniFF24.vert.ss08")
    ss = GlyphInfo("Encoding")
    st = [48, 61, 66, 70] # 保管した縦書き文字の頭からＤＱＶＺまでの数
    j = 0
    while (j < SizeOf(st))
        Select(${address_store_vert} + st[j]); Copy() # 保管した縦書きのＤＱＶＺ
        Select(ss + j); Paste() # 縦書きのss08用ＤＱＶＺ
        Select(${address_store_underline} + 2); Copy() # 縦線追加
        Select(ss + j); PasteInto() # 縦書きのss08用ＤＱＶＺ
        SetWidth(${width_zenkaku})
        j += 1
    endloop

    Select(${address_store_zero} + 3); Copy() # 保管した全角のスラッシュ無し０
    Select("uniFF10.ss10"); Paste() # 横書きのスラッシュ無し０
    Select(${address_store_underline}); Copy() # 下線追加
    Select("uniFF10.ss10"); PasteInto() # 横書きのスラッシュ無し０
    SetWidth(${width_zenkaku})

    Select(${address_store_zero} + 3); Copy() # 保管した全角のスラッシュ無し０
    Select("uniFF10.vert.ss10"); Paste() # 縦書きのスラッシュ無し０
    Select(${address_store_underline} + 2); Copy() # 縦線追加
    Select("uniFF10.vert.ss10"); PasteInto() # 縦書きのスラッシュ無し０
    SetWidth(${width_zenkaku})

    j = 0
    k = 0
    while (k < 96)
        Select(${address_store_zenhan} + k); Copy() # 保管した全角半角文字
        Select(0uff01 + j); Paste() # 全角半角形
        Select(${address_store_underline}); Copy() # 下線追加
        Select(0uff01 + j); PasteInto() # 全角半角形
        SetWidth(${width_zenkaku})
        j += 1
        k += 1
    endloop
    while (k < 159)
        Select(${address_store_zenhan} + k); Copy() # 保管した全角半角文字
        Select(0uff01 + j); Paste() # 全角半角形
        Select(${address_store_underline} + 1); Copy() # 下線追加
        Select(0uff01 + j); PasteInto() # 全角半角形
        SetWidth(${width_hankaku})
        j += 1
        k += 1
    endloop
    j = 0
    while (k < 166)
        Select(${address_store_zenhan} + k); Copy() # 保管した全角半角文字
        Select(0uffe0 + j); Paste() # 全角半角形
        Select(${address_store_underline}); Copy() # 下線追加
        Select(0uffe0 + j); PasteInto() # 全角半角形
        SetWidth(${width_zenkaku})
        j += 1
        k += 1
    endloop
    hori = [0u309b, 0u309c, 0u203c, 0u2047,\
            0u2048, 0u2049] # ゛゜‼⁇ ⁈⁉
    j = 0
    while (k < 172)
        Select(${address_store_zenhan} + k); Copy() # 保管した全角半角文字
        Select(hori[j]); Paste()
        Select(${address_store_underline}); Copy() # 下線追加
        Select(hori[j]); PasteInto()
        SetWidth(${width_zenkaku})
        j += 1
        k += 1
    endloop

# --------------------------------------------------

# Save oblique style font
    Print("Save " + output_family + "-" + output_style + ".ttf")
    Generate(output_family + "-" + output_style + ".ttf", "", 0x04)
 #    Generate(output_family + "-" + output_style + ".ttf", "", 0x84)
    Close()
    Print("")

    i += 1
endloop

Quit()
_EOT_

################################################################################
# Generate font patcher
################################################################################

cat > ${tmpdir}/${font_patcher} << _EOT_
#!$fontforge_command -script

usage = "Usage: ${font_patcher} fontfamily-fontstyle.nopatch.ttf ..."

# Get arguments
if (\$argc == 1)
    Print(usage)
    Quit()
endif

Print("- Patch the generated fonts -")

# Begin loop
i = 1
while (i < \$argc)
# Check filename
    input_ttf = \$argv[i]
    input_nop = input_ttf:t:r # :t:r ファイル名のみ抽出
    if (input_ttf:t:e != "ttf") # :t:e 拡張子のみ抽出
        Print(usage)
        Quit()
    endif
    input     = input_nop:t:r # :t:r ファイル名のみ抽出
    if (input_nop:t:e != "nopatch") # :t:e 拡張子のみ抽出
        Print(usage)
        Quit()
    endif

    hypen_index = Strrstr(input, '-') # '-'を後ろから探す('-'から前の文字数を取得、見つからないと-1)
    if (hypen_index == -1)
        Print(usage)
        Quit()
    endif

# Get parameters
    fontfamily = Strsub(input, 0, hypen_index) # 始めから'-'までを取得 (ファミリー名)
    input_style  = Strsub(input, hypen_index + 1) # '-'から後ろを取得 (スタイル)

    fontfamilysuffix = "${font_familyname_suffix}"
    version = "${font_version}"

    if (input_style == "BoldOblique")
        output_style = input_style
        style        = "Bold Oblique"
    else
        output_style = input_style
        style        = input_style
    endif

# Open file and set configuration
    Print("Open " + input_ttf)
    Open(input_ttf)

    if (fontfamilysuffix != "")
        SetFontNames(fontfamily + fontfamilysuffix + "-" + output_style, \
                     \$familyname + " " + fontfamilysuffix, \
                     \$familyname + " " + fontfamilysuffix + " " + style, \
                     style, \
                     "", version)
    else
        SetFontNames(fontfamily + "-" + output_style, \
                     \$familyname, \
                     \$familyname + " " + style, \
                     style, \
                     "", version)
    endif
    SetTTFName(0x409, 2, style)
    SetTTFName(0x409, 3, "FontForge ${fontforge_version} : " + "FontTools ${ttx_version} : " + \$fullname + " : " + Strftime("%d-%m-%Y", 0))

# --------------------------------------------------

# 全角スペース消去
    if ("${visible_zenkaku_space_flag}" == "false")
        Print("Option: Disable visible zenkaku space")
        Select(0u3000); Clear(); SetWidth(${width_zenkaku}) # 全角スペース
    endif

# 半角スペース消去
    if ("${visible_hankaku_space_flag}" == "false")
        Print("Option: Disable visible hankaku space")
        Select(0u0020); Clear(); SetWidth(${width_hankaku}) # 半角スペース
        Select(0u00a0); Clear(); SetWidth(${width_hankaku}) # ノーブレークスペース
    endif

# 下線付きの全角・半角形を元に戻す
    if ("${underline_flag}" == "false")
        Print("Option: Disable zenkaku hankaku underline")
        k = 0
        # 全角縦書き
        j = 0
        while (j < 109)
            Select(${address_store_vert} + k); Copy()
            Select(${address_vert_bracket} + j); Paste()
            SetWidth(${width_zenkaku})
            j += 1
            k += 1
        endloop

        # 全角横書き
        j = 0 # ！-｠
        while (j < 96)
            Select(${address_store_vert} + k); Copy()
            Select(0uff01 + j); Paste()
            SetWidth(${width_zenkaku})
            j += 1
            k += 1
        endloop

        # 半角横書き
        j = 0 # ｡-ﾟ
        while (j < 63)
            Select(${address_store_vert} + k); Copy();
            Select(0uff61 + j); Paste()
            SetWidth(${width_hankaku})
            j += 1
            k += 1
        endloop

        # 全角横書き (続き)
        j = 0 # ￠-￦
        while (j < 7)
            Select(${address_store_vert} + k); Copy()
            Select(0uffe0 + j); Paste()
            SetWidth(${width_zenkaku})
            j += 1
            k += 1
        endloop
        orig = [0u309b, 0u309c, 0u203c, 0u2047,\
                0u2048, 0u2049] # ゛゜‼⁇ ⁈⁉
        j = 0
        while (j < SizeOf(orig))
            Select(${address_store_vert} + k); Copy()
            Select(orig[j]); Paste()
            SetWidth(${width_zenkaku})
            j += 1
            k += 1
        endloop

        # 点字
        j = 0
        while (j < 256)
            Select(${address_store_braille} + j); Copy()
            Select(0u2800 + j); Paste()
            SetWidth(${width_hankaku})
            j += 1
        endloop

    endif

# 識別性向上グリフを元に戻す
    if ("${improve_visibility_flag}" == "false")
        Print("Option: Disable glyphs with improved visibility")
        # 破線・ウロコ等
        k = 0
        orig = [0u2044, 0u007c,\
                0u30a0, 0u2f23, 0u2013, 0ufe32, 0u2014, 0ufe31] # ⁄| ゠⼣–︲—︱
        j = 0
        while (j < SizeOf(orig))
            Select(${address_store_visi_latin} + k); Copy()
            Select(orig[j]); Paste()
            if (j <= 1 || j == 4)
                SetWidth(${width_hankaku})
            else
                SetWidth(${width_zenkaku})
            endif
            j += 1
            k += 1
        endloop
        j = 0
        while (j < 20) # ➀-➓
            Select(${address_store_visi_latin} + k); Copy()
            Select(0u2780 + j); Paste()
            SetWidth(${width_zenkaku})
            j += 1
            k += 1
        endloop
        orig = [0u3007, 0u4e00, 0u4e8c, 0u4e09,\
                0u5de5, 0u529b, 0u5915, 0u535c,\
                0u53e3] # 〇一二三 工力夕卜 口
        j = 0
        while (j < SizeOf(orig))
            Select(${address_store_visi_latin} + k); Copy()
            Select(orig[j]); Paste()
            SetWidth(${width_zenkaku})
            j += 1
            k += 1
        endloop

        Select(${address_store_d_hyphen}); Copy() # 縦書き゠
        Select(${address_vert_dh}); Paste()
        SetWidth(${width_zenkaku})

        if ("${liga_flag}" == "true")
            Select(${address_store_liga}); Copy() # ||
            Select(0ue104); Paste()
            SetWidth(${width_hankaku})
        endif
    endif

# DQVZのクロスバー等消去
    if ("${mod_flag}" == "false")
        Print("Option: Disable modified D,Q,V and Z")
        if ("${underline_flag}" == "false")
            k = 0
        else
            k = ${num_mod_glyphs} * 3
        endif
        j = 0
        orig = [0u0044, 0u0051, 0u0056, 0u005a,\
                0uff24, 0uff31, 0uff36, 0uff3a,\
               "uniFF24.vert", "uniFF31.vert", "uniFF36.vert", "uniFF3A.vert"] # DQVZＤＱＶＺ縦書きＤＱＶＺ
        while (j < SizeOf(orig))
            Select(${address_store_mod} + j + k); Copy()
            Select(orig[j]); Paste()
            if (j <= ${num_mod_glyphs} - 1)
                SetWidth(${width_hankaku})
            else
                SetWidth(${width_zenkaku})
            endif
            j += 1
        endloop
    endif

# スラッシュ無し0
    if ("${slashed_zero_flag}" == "false")
        Print("Option: Disable slashed zero")
        # 半角、全角
        zero = [0u0030, 0u2070, 0u2080, 0u0000,\
                0uff10, "uniFF10.vert"] # 0⁰₀０縦書き０ (0u0000はダミー)
        j = 0
        while (j < SizeOf(zero))
            if (j != 3)
                Select(${address_store_zero} + j); Copy()
                Select(zero[j]); Paste()
                if (j < 3)
                    SetWidth(${width_hankaku})
                else
                    SetWidth(${width_zenkaku})
                endif
            endif
            j += 1
        endloop

        # 下線無し
        if ("${underline_flag}" == "false")
            Select(${address_store_zero} + 3); Copy()
            Select(0uff10) # ０
            SelectMore("uniFF10.vert") # 縦書き０
            Paste()
            SetWidth(${width_zenkaku})
        endif

        # 桁区切り
        j = 0
        while (j < 4)
            Select(${address_ss_zero} + 3 + j); Copy()
            Select(${address_calt_figure} + j * 10); Paste()
            SetWidth(${width_hankaku})
            j += 1
        endloop

    endif

# 桁区切りなし・小数を元に戻す
    if ("${separator_flag}" == "false")
        Print("Option: Disable thousands separator")
        j = 0
        while (j < 40)
            Select(0u0030 + j % 10); Copy() # 0-9
            Select(${address_calt_figure} + j); Paste()
            j += 1
        endloop
    endif

# 一部の記号文字を削除 (カラー絵文字フォントとの組み合わせ用)
    if ("${emoji_flag}" == "false")
        Print("Option: Reduce the number of emoji glyphs")

 #        Select(0u0023)             # #
 #        SelectMore(0u002a)         # *
 #        SelectMore(0u0030, 0u0039) # 0 - 9
 #        SelectMore(0u00a9)         # ©
 #        SelectMore(0u00ae)         # ®
        Select(0u203c)             # ‼
        SelectMore(0u2049)         # ⁉
 #        SelectMore(0u2122)         # ™
        SelectMore(0u2139)         # ℹ
        SelectMore(0u2194, 0u2199) # ↔↕↖↗↘↙
        SelectMore(0u21a9, 0u21aa) # ↩↪
        SelectMore(0u231a, 0u231b) # ⌚⌛
        SelectMore(0u2328)         # ⌨
        SelectMore(0u23cf)         # ⏏
        SelectMore(0u23e9, 0u23ec) # ⏩⏪⏫⏫⏬
        SelectMore(0u23ed, 0u23ee) # ⏭⏮
        SelectMore(0u23ef)         # ⏯
        SelectMore(0u23f0)         # ⏰
        SelectMore(0u23f1, 0u23f2) # ⏱⏲
        SelectMore(0u23f3)         # ⏳
        SelectMore(0u23f8, 0u23fa) # ⏸⏹⏺
 #        SelectMore(0u24c2)         # Ⓜ
        SelectMore(0u25aa, 0u25ab) # ▪▫
        SelectMore(0u25b6)         # ▶
        SelectMore(0u25c0)         # ◀
        SelectMore(0u25fb, 0u25fe) # ◻◾
        SelectMore(0u2600, 0u2601) # ☀☁
        SelectMore(0u2602, 0u2603) # ☂☃
        SelectMore(0u2604)         # ☄
        SelectMore(0u260e)         # ☎
        SelectMore(0u2611)         # ☑
        SelectMore(0u2614, 0u2615) # ☔☕
        SelectMore(0u2618)         # ☘
        SelectMore(0u261d)         # ☝
        SelectMore(0u2620)         # ☠
        SelectMore(0u2622, 0u2623) # ☢☣
        SelectMore(0u2626)         # ☦
        SelectMore(0u262a)         # ☪
        SelectMore(0u262e)         # ☮
        SelectMore(0u262f)         # ☯
        SelectMore(0u2638, 0u2639) # ☸☹
        SelectMore(0u263a)         # ☺
        SelectMore(0u2640)         # ♀
        SelectMore(0u2642)         # ♂
        SelectMore(0u2648, 0u2653) # ♈♉♊♋♌♍♎♏♐♑♒♓
        SelectMore(0u265f)         # ♟
        SelectMore(0u2660)         # ♠
        SelectMore(0u2663)         # ♣
        SelectMore(0u2665, 0u2666) # ♥♦
        SelectMore(0u2668)         # ♨
        SelectMore(0u267b)         # ♻
        SelectMore(0u267e)         # ♾
        SelectMore(0u267f)         # ♿
        SelectMore(0u2692)         # ⚒
        SelectMore(0u2693)         # ⚓
        SelectMore(0u2694)         # ⚔
        SelectMore(0u2695)         # ⚕
        SelectMore(0u2696, 0u2697) # ⚖⚗
        SelectMore(0u2699)         # ⚙
        SelectMore(0u269b, 0u269c) # ⚛⚜
        SelectMore(0u26a0, 0u26a1) # ⚠⚡
        SelectMore(0u26a7)         # ⚧
        SelectMore(0u26aa, 0u26ab) # ⚪⚫
        SelectMore(0u26b0, 0u26b1) # ⚰⚱
        SelectMore(0u26bd, 0u26be) # ⚽⚾
        SelectMore(0u26c4, 0u26c5) # ⛄⛅
        SelectMore(0u26c8)         # ⛈
        SelectMore(0u26ce)         # ⛎
        SelectMore(0u26cf)         # ⛏
        SelectMore(0u26d1)         # ⛑
        SelectMore(0u26d3)         # ⛓
        SelectMore(0u26d4)         # ⛔
        SelectMore(0u26e9)         # ⛩
        SelectMore(0u26ea)         # ⛪
        SelectMore(0u26f0, 0u26f1) # ⛰⛱
        SelectMore(0u26f2, 0u26f3) # ⛲⛳
        SelectMore(0u26f4)         # ⛴
        SelectMore(0u26f5)         # ⛵
        SelectMore(0u26f7, 0u26f9) # ⛷⛸⛹
        SelectMore(0u26fa)         # ⛺
        SelectMore(0u26fd)         # ⛽
        SelectMore(0u2702)         # ✂
        SelectMore(0u2705)         # ✅
        SelectMore(0u2708, 0u270c) # ✈✉✊✋✌
        SelectMore(0u270d)         # ✍
        SelectMore(0u270f)         # ✏
        SelectMore(0u2712)         # ✒
        SelectMore(0u2714)         # ✔
        SelectMore(0u2716)         # ✖
        SelectMore(0u271d)         # ✝
        SelectMore(0u2721)         # ✡
        SelectMore(0u2728)         # ✨
        SelectMore(0u2733, 0u2734) # ✳✴
        SelectMore(0u2744)         # ❄
        SelectMore(0u2747)         # ❇
        SelectMore(0u274c)         # ❌
        SelectMore(0u274e)         # ❎
        SelectMore(0u2753, 0u2755) # ❓❔❕
        SelectMore(0u2757)         # ❗
        SelectMore(0u2763)         # ❣
        SelectMore(0u2764)         # ❤
        SelectMore(0u2795, 0u2797) # ➕➖➗
        SelectMore(0u27a1)         # ➡
        SelectMore(0u27b0)         # ➰
        SelectMore(0u27bf)         # ➿
        SelectMore(0u2934, 0u2935) # ⤴⤵
        SelectMore(0u2b05, 0u2b07) # ⬅⬆⬇
        SelectMore(0u2b1b, 0u2b1c) # ⬛⬜
        SelectMore(0u2b50)         # ⭐
        SelectMore(0u2b55)         # ⭕
        SelectMore(0u3030)         # 〰
        SelectMore(0u303d)         # 〽
        SelectMore(0u3297)         # ㊗
        SelectMore(0u3299)         # ㊙

        SelectMore(0u1f310)        # 🌐
        SelectMore(0u1f3a4)        # 🎤
        SelectMore(0u1f3b5, 0u1f3b6) # 🎵🎶
        SelectMore(0u1f4a9)        # 💩
        SelectMore(0u1f512)        # 🔒
        SelectMore(0u1f916)        # 🤖
        Clear(); DetachAndRemoveGlyphs()
    endif

# calt用異体字上書き
    if ("${calt_flag}" == "true")
        Print("Overwrite calt glyphs")
        k = ${address_calt_AL}
        j = 0
        while (j < 26)
            Select(0u0041 + j); Copy() # A
            Select(k); Paste()
            Move(-${move_x_calt_latin}, 0)
            SetWidth(${width_hankaku})
            j += 1
            k += 1
        endloop
        j = 0
        while (j < 26)
            Select(0u0061 + j); Copy() # a
            Select(k); Paste()
            Move(-${move_x_calt_latin}, 0)
            SetWidth(${width_hankaku})
            j += 1
            k += 1
        endloop

        k = ${address_calt_AR}
        j = 0
        while (j < 26)
            Select(0u0041 + j); Copy() # A
            Select(k); Paste()
            Move(${move_x_calt_latin}, 0)
            SetWidth(${width_hankaku})
            j += 1
            k += 1
        endloop
        j = 0
        while (j < 26)
            Select(0u0061 + j); Copy() # a
            Select(k); Paste()
            Move(${move_x_calt_latin}, 0)
            SetWidth(${width_hankaku})
            j += 1
            k += 1
        endloop

        Select(0u007c); Copy() # |
        Select(${address_calt_hyphenL} + ${address_calt_barDLR}); Paste() # 左に移動した |
        Move(-${move_x_calt_symbol}, 0)
        SetWidth(${width_hankaku})

        Select(0u007c); Copy() # |
        Select(${address_calt_hyphenR} + ${address_calt_barDLR}); Paste() # 右に移動した |
        Move(${move_x_calt_symbol}, 0)
        SetWidth(${width_hankaku})

        Select(0u007c); Copy() # |
        Select(${address_calt_barD}); Paste() # 下に移動した |
        Move(0, ${move_y_calt_bar})
        SetWidth(${width_hankaku})

        Select(0u007c); Copy() # |
        Select(${address_calt_hyphenL} + ${address_calt_barDLR} + 1); Paste() # 左下に移動した |
        Move(-${move_x_calt_symbol}, ${move_y_calt_bar})
        SetWidth(${width_hankaku})

        Select(0u007c); Copy() # |
        Select(${address_calt_hyphenR} + ${address_calt_barDLR} + 1); Paste() # 右下に移動した |
        Move(${move_x_calt_symbol}, ${move_y_calt_bar})
        SetWidth(${width_hankaku})

        Select(0u007c); Copy() # |
        Select(${address_calt_barD} + 7); Paste() # 上に移動した | (括弧用)
        Move(0, ${move_y_calt_bar2})
        SetWidth(${width_hankaku})

        Select(0u007c); Copy() # |
        Select(${address_calt_hyphenL} + ${address_calt_barDLR} + 4); Paste() # 左上に移動した | (括弧用)
        Move(-${move_x_calt_symbol}, ${move_y_calt_bar2})
        SetWidth(${width_hankaku})

        Select(0u007c); Copy() # |
        Select(${address_calt_hyphenR} + ${address_calt_barDLR} + 4); Paste() # 右上に移動した | (括弧用)
        Move(${move_x_calt_symbol}, ${move_y_calt_bar2})
        SetWidth(${width_hankaku})

    else # calt非対応の場合、ダミーのフィーチャを削除
        Print("Remove calt lookups and glyphs")
        lookups = GetLookups("GSUB"); numlookups = SizeOf(lookups); j = 0
        while (j < numlookups)
            if (${lookupIndex_calt} <= j && j < ${lookupIndex_calt} + ${num_calt_lookups})
                Print("Remove GSUB_" + lookups[j])
                RemoveLookup(lookups[j])
            endif
            j += 1
        endloop

        Select(${address_calt_start}, ${address_calt_end}) # calt非対応の場合、calt用異体字削除
        Clear(); DetachAndRemoveGlyphs()
    endif

# 保管したグリフ消去
    Print("Remove stored glyphs")
    Select(${address_store_start}, ${address_store_end}); Clear() # 保管したグリフを消去

# ss 用異体字消去
    if ("${ss_flag}" == "false")
        Print("Remove ss lookups and glyphs")
        lookups = GetLookups("GSUB"); numlookups = SizeOf(lookups); j = 0
        while (j < numlookups)
            if (${lookupIndex_ss} <= j && j < ${lookupIndex_ss} + ${num_ss_lookups})
                Print("Remove GSUB_" + lookups[j])
                RemoveLookup(lookups[j])
            endif
            j += 1
        endloop

        Select(${address_ss_start}, ${address_ss_end})
        Clear(); DetachAndRemoveGlyphs()
    endif

# --------------------------------------------------

    SetGasp(65535, 15) # Windows のジャギー対策
# Save patched font
    Print("Save " + fontfamily + fontfamilysuffix + "-" + output_style + ".ttf")
    Generate(fontfamily + fontfamilysuffix + "-" + output_style + ".ttf", "", 0x04)
 #    Generate(fontfamily + fontfamilysuffix + "-" + output_style + ".ttf", "", 0x84)
    Close()
    Print("")

    i += 1
endloop

Quit()
_EOT_

################################################################################
# Generate custom fonts
################################################################################

if [ "${patch_only_flag}" = "false" ]; then
    rm -f ${font_familyname}*.ttf

    # 下書きモード、一時作成ファイルを残す以外で font_generator に変更が無く、すでにパッチ前フォントが作成されていた場合それを呼び出す
    if [ "${draft_flag}" = "false" ] && [ "${leaving_tmp_flag}" = "false" ]; then
        output_data=$(sha256sum font_generator.sh | cut -d ' ' -f 1)
        output_data=${output_data}"_"$(sha256sum "${settings}.txt" | cut -d ' ' -f 1)
        if [ "${nerd_flag}" = "false" ]; then
            nopatchsetdir_name="e"
        fi
        if [ "${oblique_flag}" = "false" ]; then
            nopatchsetdir_name="${nopatchsetdir_name}o"
        fi
        if [ "${loose_flag}" != "false" ]; then
            nopatchsetdir_name="${nopatchsetdir_name}w"
        fi
        if [ "${liga_flag}" != "false" ]; then
            nopatchsetdir_name="${nopatchsetdir_name}L"
        fi
        if [ "${term_flag}" != "false" ]; then
            nopatchsetdir_name="${nopatchsetdir_name}a"
        fi
        nopatchsetdir_name="${font_familyname}_${nopatchsetdir_name}"
        file_data_txt=$(find "./${nopatchdir_name}/${nopatchsetdir_name}" -maxdepth 1 -name "${fileDataName}.txt" | head -n 1)
        if [ -n "${file_data_txt}" ]; then
            input_data=$(head -n 1 "${nopatchdir_name}/${nopatchsetdir_name}/${fileDataName}.txt")
            if [ "${input_data}" = "${output_data}" ]; then
                echo "font_generator and settings file are unchanged"
                echo "Use saved nopatch fonts"
                cp -f ${nopatchdir_name}/${nopatchsetdir_name}/${font_familyname}-*.nopatch.ttf "."
                compose_flag="false"
                echo
            fi
        fi
    fi

    # 下書きモードかパッチ前フォントが作成されていなかった場合フォントを合成し直す
    if [ "${compose_flag}" = "true" ]; then
        if [ "${draft_flag}" = "false" ] && [ "${leaving_tmp_flag}" = "false" ]; then
            echo "font_generator settings are changed or nopatch fonts not exist"
            echo "Make new nopatch fonts"
            echo
        fi

        # カスタムフォント生成
        $fontforge_command -script ${tmpdir}/${modified_latin_generator} \
            2> $redirection_stderr || exit 4
        $fontforge_command -script ${tmpdir}/${custom_font_generator} \
            2> $redirection_stderr || exit 4

        # Nerd fonts追加
        if [ "${nerd_flag}" = "true" ]; then
            $fontforge_command -script ${tmpdir}/${modified_nerd_generator} \
                2> $redirection_stderr || exit 4
            $fontforge_command -script ${tmpdir}/${merged_nerd_generator} \
                ${font_familyname}${font_familyname_suffix}-Regular.ttf \
                2> $redirection_stderr || exit 4
            $fontforge_command -script ${tmpdir}/${merged_nerd_generator} \
                ${font_familyname}${font_familyname_suffix}-Bold.ttf \
                2> $redirection_stderr || exit 4
        fi

        # パラメータ調整
        $fontforge_command -script ${tmpdir}/${parameter_modificator} \
            ${font_familyname}${font_familyname_suffix}-Regular.ttf \
            2> $redirection_stderr || exit 4
        $fontforge_command -script ${tmpdir}/${parameter_modificator} \
            ${font_familyname}${font_familyname_suffix}-Bold.ttf \
            2> $redirection_stderr || exit 4

        # オブリーク作成
        if [ "${oblique_flag}" = "true" ]; then
        $fontforge_command -script ${tmpdir}/${oblique_converter} \
            ${font_familyname}${font_familyname_suffix}-Regular.ttf \
            2> $redirection_stderr || exit 4
        $fontforge_command -script ${tmpdir}/${oblique_converter} \
            ${font_familyname}${font_familyname_suffix}-Bold.ttf \
            2> $redirection_stderr || exit 4
        fi

        # ファイル名を変更
        find . -maxdepth 1 -not -name "*.*.ttf" | \
        grep -e "${font_familyname}${font_familyname_suffix}-.*\.ttf$" | while read line
        do
            style_ttf=${line#*-}; style=${style_ttf%%.ttf}
            echo "Rename to ${font_familyname}-${style}.nopatch.ttf"
            mv "${line}" "${font_familyname}-${style}.nopatch.ttf"
            echo
        done

        # 下書きモード、一時作成ファイルを残す以外でフォントを作成した場合、パッチ前フォントと font_generator の情報を保存
        if [ "${draft_flag}" = "false" ] && [ "${leaving_tmp_flag}" = "false" ]; then
            echo "Save nopatch fonts"
            rm -rf "${nopatchdir_name}/${nopatchsetdir_name}"
            mkdir -p "${nopatchdir_name}/${nopatchsetdir_name}"
            printf "${output_data}" > "${nopatchdir_name}/${nopatchsetdir_name}/${fileDataName}.txt"
            cp -f ${font_familyname}-*.nopatch.ttf "${nopatchdir_name}/${nopatchsetdir_name}/."
            echo
        fi
    fi
fi

# パッチ適用
if [ "${patch_flag}" = "true" ]; then
    find . -maxdepth 1 -name "${font_familyname}-*.nopatch.ttf" | while read line
    do
        font_ttf=$(basename ${line})
        $fontforge_command -script ${tmpdir}/${font_patcher} \
            ${font_ttf} \
            2> $redirection_stderr || exit 4
    done
fi

# Remove temporary directory
if [ "${patch_only_flag}" = "false" ] && [ "${patch_flag}" = "true" ]; then
 rm -f "${font_familyname}*.nopatch.ttf"
fi
if [ "${leaving_tmp_flag}" = "false" ]; then
    echo "Remove temporary files"
    rm -rf $tmpdir
    echo
fi

# Exit
echo "Finished generating custom fonts."
echo
exit 0
