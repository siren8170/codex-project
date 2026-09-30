"use strict";

const $ = (selector) => document.querySelector(selector);
const today = () => new Date();
const dateKey = (date) => `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}-${String(date.getDate()).padStart(2, "0")}`;
const dateText = (date) => new Intl.DateTimeFormat("ko-KR", { year: "numeric", month: "long", day: "numeric", weekday: "long" }).format(date);

const homeView = $("#home-view");
const calendarView = $("#calendar-view");
const viewToggle = $("#view-toggle");
const recordButton = $("#record-button");
const stopButton = $("#stop-button");
const statusMessage = $("#recording-message");
const recordingState = $("#recording-state");
const recordingTime = $("#recording-time");
const recordingList = $("#recording-list");
const recordingCount = $("#recording-count");
const calendarDays = $("#calendar-days");

let recorder = null;
let stream = null;
let chunks = [];
let startedAt = 0;
let timer = null;
let recordingDate = "";
let visibleMonth = new Date(today().getFullYear(), today().getMonth(), 1);
let selectedDate = today();
let objectUrls = [];

const sampleDiaries = [
  { title: "작은 일도 기억하고 싶은 날", text: "아침에 조금 늦게 일어났지만 서둘러 학교에 갔다. 점심시간에는 친구와 운동장을 걸으며 이야기를 나눴다.\n\n별일 없는 하루 같았지만, 돌아보니 웃었던 순간이 몇 번 있었다. 그걸 기억해 두고 싶다." },
  { title: "친구와 나눈 이야기", text: "수업이 끝난 뒤 친구와 편의점에 들렀다. 좋아하는 간식을 고르며 시험이 끝나면 하고 싶은 일을 이야기했다.\n\n집으로 돌아오는 길에는 하늘이 맑았다. 짧은 대화 덕분에 마음이 한결 가벼워졌다." },
  { title: "조금씩 나아가는 하루", text: "어려웠던 수학 문제를 다시 풀어 봤다. 처음에는 막막했지만 천천히 읽으니 풀이가 보였다.\n\n오늘 다 해결하지는 못했어도 어제보다 한 걸음 나아간 것 같아 뿌듯했다." }
];

function diaryFor(date) {
  return sampleDiaries[(date.getDate() - 1) % sampleDiaries.length];
}

function openDatabase() {
  return new Promise((resolve, reject) => {
    if (!window.indexedDB) { reject(new Error("이 브라우저는 녹음 저장을 지원하지 않습니다.")); return; }
    const request = indexedDB.open("one-day-audio", 1);
    request.onupgradeneeded = () => request.result.createObjectStore("recordings", { keyPath: "id" });
    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error);
  });
}

async function withStore(mode, action) {
  const db = await openDatabase();
  return new Promise((resolve, reject) => {
    const transaction = db.transaction("recordings", mode);
    const store = transaction.objectStore("recordings");
    let result;
    try { result = action(store); } catch (error) { db.close(); reject(error); return; }
    transaction.oncomplete = () => { db.close(); resolve(result?.result); };
    transaction.onerror = () => { db.close(); reject(transaction.error); };
    transaction.onabort = () => { db.close(); reject(transaction.error); };
  });
}

async function removeOldRecordings() {
  const current = dateKey(today());
  const items = await withStore("readonly", (store) => store.getAll());
  const oldItems = items.filter((item) => item.date !== current);
  if (oldItems.length) await withStore("readwrite", (store) => oldItems.forEach((item) => store.delete(item.id)));
}

function releaseAudioUrls() {
  objectUrls.forEach((url) => URL.revokeObjectURL(url));
  objectUrls = [];
}

async function renderRecordings() {
  try {
    await removeOldRecordings();
    const items = await withStore("readonly", (store) => store.getAll());
    items.sort((a, b) => b.createdAt - a.createdAt);
    releaseAudioUrls();
    recordingList.replaceChildren();
    recordingCount.textContent = String(items.length);
    if (!items.length) {
      const empty = document.createElement("p");
      empty.className = "empty-message";
      empty.textContent = "아직 저장된 녹음이 없어요.";
      recordingList.append(empty);
      return;
    }
    items.forEach((item, index) => {
      const row = document.createElement("div");
      row.className = "recording-item";
      const name = document.createElement("span");
      name.className = "recording-name";
      name.textContent = `오늘의 녹음 ${items.length - index}`;
      const time = document.createElement("span");
      time.className = "recording-time";
      time.textContent = new Intl.DateTimeFormat("ko-KR", { hour: "2-digit", minute: "2-digit" }).format(new Date(item.createdAt));
      const audio = document.createElement("audio");
      audio.controls = true;
      audio.setAttribute("aria-label", name.textContent);
      const url = URL.createObjectURL(item.blob);
      objectUrls.push(url);
      audio.src = url;
      row.append(name, time, audio);
      recordingList.append(row);
    });
  } catch (error) {
    recordingList.replaceChildren();
    const message = document.createElement("p");
    message.className = "empty-message";
    message.textContent = "녹음 목록을 불러올 수 없어요. 브라우저 저장소 설정을 확인해 주세요.";
    recordingList.append(message);
    statusMessage.textContent = error.message;
  }
}

function updateTimer() {
  const seconds = Math.floor((Date.now() - startedAt) / 1000);
  recordingTime.textContent = `${String(Math.floor(seconds / 60)).padStart(2, "0")}:${String(seconds % 60).padStart(2, "0")}`;
}

function releaseMicrophone() {
  stream?.getTracks().forEach((track) => track.stop());
  stream = null;
}

async function startRecording() {
  if (recorder || recordButton.disabled) return;
  if (!navigator.mediaDevices?.getUserMedia || !window.MediaRecorder) {
    statusMessage.textContent = "이 브라우저에서는 녹음할 수 없어요. 마이크 사용이 가능한 브라우저에서 열어 주세요.";
    return;
  }
  recordButton.disabled = true;
  statusMessage.textContent = "마이크 사용 권한을 확인하고 있어요…";
  try {
    stream = await navigator.mediaDevices.getUserMedia({ audio: true });
    const preferredType = ["audio/webm;codecs=opus", "audio/mp4", "audio/webm"].find((type) => MediaRecorder.isTypeSupported(type));
    recorder = preferredType ? new MediaRecorder(stream, { mimeType: preferredType }) : new MediaRecorder(stream);
    chunks = [];
    recordingDate = dateKey(today());
    recorder.ondataavailable = (event) => { if (event.data.size) chunks.push(event.data); };
    recorder.onstop = saveRecording;
    recorder.onerror = () => { statusMessage.textContent = "녹음 중 문제가 생겼어요. 다시 시도해 주세요."; stopRecording(); };
    recorder.start();
    startedAt = Date.now();
    recordingTime.textContent = "00:00";
    timer = setInterval(updateTimer, 1000);
    stopButton.disabled = false;
    recordingState.textContent = "녹음 중이에요";
    statusMessage.textContent = "이야기를 마친 뒤 녹음 중지를 눌러 주세요.";
    $(".recorder-card").classList.add("is-recording");
  } catch (error) {
    releaseMicrophone();
    recorder = null;
    recordButton.disabled = false;
    statusMessage.textContent = error.name === "NotAllowedError" ? "마이크 권한이 필요해요. 브라우저 설정에서 허용해 주세요." : "마이크를 사용할 수 없어요. 연결과 브라우저 권한을 확인해 주세요.";
  }
}

function stopRecording() {
  if (!recorder || recorder.state === "inactive") return;
  stopButton.disabled = true;
  clearInterval(timer);
  updateTimer();
  recordingState.textContent = "녹음을 저장하고 있어요";
  statusMessage.textContent = "녹음 파일을 브라우저에 저장하고 있어요…";
  recorder.stop();
  releaseMicrophone();
  $(".recorder-card").classList.remove("is-recording");
}

async function saveRecording() {
  const type = recorder?.mimeType || chunks[0]?.type || "audio/webm";
  const blob = new Blob(chunks, { type });
  recorder = null;
  chunks = [];
  recordButton.disabled = false;
  recordingState.textContent = "녹음할 준비가 되었어요";
  if (!blob.size) { statusMessage.textContent = "녹음된 소리가 없어요. 다시 녹음해 주세요."; return; }
  if (recordingDate !== dateKey(today())) { statusMessage.textContent = "날짜가 바뀌어 지난날 녹음은 저장하지 않았어요."; await renderRecordings(); return; }
  try {
    await withStore("readwrite", (store) => store.put({ id: `${Date.now()}-${Math.random().toString(36).slice(2)}`, date: recordingDate, createdAt: Date.now(), blob }));
    statusMessage.textContent = "녹음을 이 브라우저에 저장했어요. 아래에서 재생할 수 있어요.";
    await renderRecordings();
  } catch (error) {
    statusMessage.textContent = "녹음을 저장하지 못했어요. 브라우저 저장 공간을 확인해 주세요.";
  }
}

function renderDiary() {
  $("#diary-date").textContent = dateText(selectedDate);
  const content = $("#diary-content");
  content.replaceChildren();
  const diary = diaryFor(selectedDate);
  if (!diary) {
    const empty = document.createElement("p");
    empty.className = "diary-empty";
    empty.textContent = "이 날짜에는 표시할 일기가 없어요.";
    content.append(empty);
    return;
  }
  const title = document.createElement("h2");
  title.id = "diary-heading";
  title.textContent = diary.title;
  const text = document.createElement("p");
  text.className = "diary-text";
  text.textContent = diary.text;
  const badge = document.createElement("span");
  badge.className = "sample-badge";
  badge.textContent = "가상 예시 일기";
  content.append(title, text, badge);
}

function renderCalendar() {
  $("#month-label").textContent = new Intl.DateTimeFormat("ko-KR", { year: "numeric", month: "long" }).format(visibleMonth);
  calendarDays.replaceChildren();
  const year = visibleMonth.getFullYear();
  const month = visibleMonth.getMonth();
  const firstWeekday = new Date(year, month, 1).getDay();
  const daysInMonth = new Date(year, month + 1, 0).getDate();
  for (let i = 0; i < firstWeekday; i++) {
    const blank = document.createElement("span");
    blank.className = "blank";
    calendarDays.append(blank);
  }
  for (let day = 1; day <= daysInMonth; day++) {
    const date = new Date(year, month, day);
    const button = document.createElement("button");
    button.type = "button";
    button.textContent = String(day);
    button.setAttribute("aria-label", `${dateText(date)}, 예시 일기 있음`);
    if (dateKey(date) === dateKey(today())) button.classList.add("today");
    if (dateKey(date) === dateKey(selectedDate)) { button.classList.add("selected"); button.setAttribute("aria-current", "date"); }
    button.addEventListener("click", () => { selectedDate = date; renderCalendar(); renderDiary(); });
    calendarDays.append(button);
  }
}

viewToggle.addEventListener("click", () => {
  const showCalendar = calendarView.hidden;
  calendarView.hidden = !showCalendar;
  homeView.hidden = showCalendar;
  viewToggle.innerHTML = showCalendar ? '녹음 화면 <span aria-hidden="true">↗</span>' : '캘린더 보기 <span aria-hidden="true">↗</span>';
  viewToggle.setAttribute("aria-expanded", String(showCalendar));
  if (showCalendar) { renderCalendar(); renderDiary(); }
});
recordButton.addEventListener("click", startRecording);
stopButton.addEventListener("click", stopRecording);
$("#previous-month").addEventListener("click", () => { visibleMonth = new Date(visibleMonth.getFullYear(), visibleMonth.getMonth() - 1, 1); renderCalendar(); });
$("#next-month").addEventListener("click", () => { visibleMonth = new Date(visibleMonth.getFullYear(), visibleMonth.getMonth() + 1, 1); renderCalendar(); });
document.addEventListener("visibilitychange", () => { if (!document.hidden) refreshDate(); });
setInterval(refreshDate, 60000);
function refreshDate() {
  $("#today-label").textContent = dateText(today());
  if (recordingDate && recordingDate !== dateKey(today()) && recorder?.state === "recording") stopRecording();
  renderRecordings();
  if (!calendarView.hidden) { renderCalendar(); renderDiary(); }
}
window.addEventListener("beforeunload", releaseAudioUrls);
refreshDate();
