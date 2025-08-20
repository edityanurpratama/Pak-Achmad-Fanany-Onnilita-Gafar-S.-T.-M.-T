% RiskLaptop_Octave.m
% Sistem Fuzzy Mamdani untuk Penilaian Risiko Kerusakan Laptop
% Oleh: Kelompok 02 - Kelas 5D
% Tanggal: 2024

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PERSIAPAN AWAL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Membersihkan workspace dan menutup semua figure
clear; clc; close all;

% Memuat paket fuzzy-logic-toolkit (wajib di Octave)
pkg load fuzzy-logic-toolkit

% Menampilkan pesan mulai
fprintf('==================================================\n');
fprintf('SISTEM FUZZY MAMDANI - PENILAIAN RISIKO LAPTOP\n');
fprintf('Kelompok 02 - Kelas 5D\n');
fprintf('==================================================\n\n');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 1. MEMBUAT SISTEM FUZZY MAMDANI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf('1. Membuat sistem fuzzy Mamdani...\n');

% Membuat FIS Mamdani baru dengan nama 'RiskLaptopFIS'
fis = newfis('RiskLaptopFIS', 'mamdani');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2. MENAMBAHKAN VARIABEL INPUT DAN OUTPUT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf('2. Menambahkan variabel input dan output...\n');

% Variabel Input 1: Suhu (dalam derajat Celsius)
fis = addvar(fis, 'input', 'Suhu', [30 90]);

% Variabel Input 2: Baterai (dalam persentase)
fis = addvar(fis, 'input', 'Baterai', [0 100]);

% Variabel Input 3: Pemakaian (dalam jam per hari)
fis = addvar(fis, 'input', 'Pemakaian', [0 12]);

% Variabel Output: Risiko (skor 0-100)
fis = addvar(fis, 'output', 'Risiko', [0 100]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 3. MENAMBAHKAN FUNGSI KEANGGOTAAN (MEMBERSHIP FUNCTIONS)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf('3. Menambahkan fungsi keanggotaan...\n');

% Fungsi keanggotaan untuk Suhu
fis = addmf(fis, 'input', 1, 'Rendah', 'trapmf', [30 30 50 55]);
fis = addmf(fis, 'input', 1, 'Sedang', 'trapmf', [50 60 70 75]);
fis = addmf(fis, 'input', 1, 'Tinggi', 'trapmf', [70 80 90 90]);

% Fungsi keanggotaan untuk Baterai
fis = addmf(fis, 'input', 2, 'Buruk', 'trapmf', [0 0 50 60]);
fis = addmf(fis, 'input', 2, 'Sedang', 'trapmf', [50 65 80 85]);
fis = addmf(fis, 'input', 2, 'Bagus', 'trapmf', [80 90 100 100]);

% Fungsi keanggotaan untuk Pemakaian
fis = addmf(fis, 'input', 3, 'Ringan', 'trapmf', [0 0 3 4]);
fis = addmf(fis, 'input', 3, 'Sedang', 'trapmf', [2 4 6 7]);
fis = addmf(fis, 'input', 3, 'Berat', 'trapmf', [6 8 12 12]);

% Fungsi keanggotaan untuk Risiko (Output)
fis = addmf(fis, 'output', 1, 'Rendah', 'trapmf', [0 0 30 40]);
fis = addmf(fis, 'output', 1, 'Sedang', 'trapmf', [30 50 60 70]);
fis = addmf(fis, 'output', 1, 'Tinggi', 'trapmf', [60 75 100 100]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 4. MENAMBAHKAN ATURAN FUZZY (RULE BASE)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf('4. Menambahkan aturan fuzzy...\n');

% Membuat rule base (6 aturan)
% Format: [Input1 Input2 Input3 Output Weight Operator]
% Operator: 1=AND, 2=OR
ruleList = [
    1 3 1 1 1 1;   % Jika Suhu Rendah DAN Baterai Bagus DAN Pemakaian Ringan MAKA Risiko Rendah
    2 2 2 2 1 1;   % Jika Suhu Sedang DAN Baterai Sedang DAN Pemakaian Sedang MAKA Risiko Sedang
    3 1 3 3 1 2;   % Jika Suhu Tinggi ATAU Baterai Buruk ATAU Pemakaian Berat MAKA Risiko Tinggi
    2 3 1 1 1 1;   % Jika Suhu Sedang DAN Baterai Bagus DAN Pemakaian Ringan MAKA Risiko Rendah
    1 2 3 2 1 1;   % Jika Suhu Rendah DAN Baterai Sedang DAN Pemakaian Berat MAKA Risiko Sedang
    3 3 2 2 1 1;   % Jika Suhu Tinggi DAN Baterai Bagus DAN Pemakaian Sedang MAKA Risiko Sedang
];

% Menambahkan aturan ke FIS
fis = addrule(fis, ruleList);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 5. MENGATUR METODE INFERENSI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf('5. Mengatur metode inferensi...\n');

% Mengatur metode AND (min), OR (max), implikasi (min), agregasi (max), defuzzifikasi (centroid)
fis.andMethod = 'min';
fis.orMethod = 'max';
fis.impMethod = 'min';
fis.aggMethod = 'max';
fis.defuzzMethod = 'centroid';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 6. MENYIMPAN SISTEM FUZZY KE FILE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf('6. Menyimpan sistem fuzzy ke file...\n');

% Menyimpan FIS ke file (format Octave)
save('RiskLaptopFIS.oct', 'fis');
fprintf('   Sistem fuzzy disimpan sebagai: RiskLaptopFIS.oct\n');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 7. VISUALISASI FUNGSI KEANGGOTAAN
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf('7. Membuat visualisasi fungsi keanggotaan...\n');

% Membuat direktori untuk menyimpan gambar jika belum ada
if ~exist('../images/mf_plots', 'dir')
    mkdir('../images/mf_plots');
end

% Plot fungsi keanggotaan untuk Suhu
figure('Position', [100, 100, 800, 600]);
[x, mf] = plotmf(fis, 'input', 1);
plot(x, mf);
title('Fungsi Keanggotaan - Suhu (°C)');
xlabel('Suhu (°C)');
ylabel('Derajat Keanggotaan');
legend('Rendah', 'Sedang', 'Tinggi', 'Location', 'best');
grid on;
saveas(gcf, '../images/mf_plots/MF_Suhu.png');
fprintf('   Gambar disimpan: ../images/mf_plots/MF_Suhu.png\n');

% Plot fungsi keanggotaan untuk Baterai
figure('Position', [100, 100, 800, 600]);
[x, mf] = plotmf(fis, 'input', 2);
plot(x, mf);
title('Fungsi Keanggotaan - Baterai (%)');
xlabel('Baterai (%)');
ylabel('Derajat Keanggotaan');
legend('Buruk', 'Sedang', 'Bagus', 'Location', 'best');
grid on;
saveas(gcf, '../images/mf_plots/MF_Baterai.png');
fprintf('   Gambar disimpan: ../images/mf_plots/MF_Baterai.png\n');

% Plot fungsi keanggotaan untuk Pemakaian
figure('Position', [100, 100, 800, 600]);
[x, mf] = plotmf(fis, 'input', 3);
plot(x, mf);
title('Fungsi Keanggotaan - Pemakaian (jam/hari)');
xlabel('Pemakaian (jam/hari)');
ylabel('Derajat Keanggotaan');
legend('Ringan', 'Sedang', 'Berat', 'Location', 'best');
grid on;
saveas(gcf, '../images/mf_plots/MF_Pemakaian.png');
fprintf('   Gambar disimpan: ../images/mf_plots/MF_Pemakaian.png\n');

% Plot fungsi keanggotaan untuk Risiko
figure('Position', [100, 100, 800, 600]);
[x, mf] = plotmf(fis, 'output', 1);
plot(x, mf);
title('Fungsi Keanggotaan - Risiko');
xlabel('Tingkat Risiko');
ylabel('Derajat Keanggotaan');
legend('Rendah', 'Sedang', 'Tinggi', 'Location', 'best');
grid on;
saveas(gcf, '../images/mf_plots/MF_Risiko.png');
fprintf('   Gambar disimpan: ../images/mf_plots/MF_Risiko.png\n');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 8. EVALUASI CONTOH INPUT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf('8. Mengevaluasi contoh input...\n');

% Contoh input: [Suhu, Baterai, Pemakaian]
inputContoh = [78, 55, 8];  % Suhu=78°C, Baterai=55%, Pemakaian=8 jam/hari

% Melakukan evaluasi fuzzy
outputContoh = evalfis(inputContoh, fis);

% Menampilkan hasil
fprintf('   Contoh Input:\n');
fprintf('   - Suhu: %d°C\n', inputContoh(1));
fprintf('   - Baterai: %d%%\n', inputContoh(2));
fprintf('   - Pemakaian: %d jam/hari\n', inputContoh(3));
fprintf('   Output Risiko: %.2f\n', outputContoh);

% Menentukan kategori risiko
if outputContoh < 40
    kategori = 'Rendah';
elseif outputContoh < 70
    kategori = 'Sedang';
else
    kategori = 'Tinggi';
end
fprintf('   Kategori Risiko: %s\n', kategori);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 9. EVALUASI BATCH DARI FILE CSV
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf('9. Mengevaluasi data dari file CSV...\n');

% Memeriksa apakah file data_uji.csv ada
if exist('../../data/raw/data_uji.csv', 'file') == 2
    fprintf('   File data_uji.csv ditemukan.\n');
    
    % Membaca data dari file CSV
    data = csvread('../../data/raw/data_uji.csv', 1, 0);  % Melewati header
    
    % Memisahkan input dan output actual
    X = data(:, 1:3);          % Kolom 1-3: Suhu, Baterai, Pemakaian
    Y_actual = data(:, 4);     % Kolom 4: ActualRisk
    
    % Melakukan evaluasi fuzzy untuk semua data
    Y_pred = zeros(size(Y_actual));
    for i = 1:size(X, 1)
        Y_pred(i) = evalfis(X(i, :), fis);
    end
    
    % Menghitung MSE (Mean Squared Error)
    mse = mean((Y_actual - Y_pred) .^ 2);
    fprintf('   MSE: %.4f\n', mse);
    
    % Menyimpan hasil prediksi
    hasil = [X, Y_actual, Y_pred];
    csvwrite('../../data/processed/hasil_prediksi.csv', hasil);
    fprintf('   Hasil prediksi disimpan: ../../data/processed/hasil_prediksi.csv\n');
    
    % Membuat plot perbandingan actual vs predicted
    figure('Position', [100, 100, 1000, 600]);
    plot(1:length(Y_actual), Y_actual, 'b-o', 'LineWidth', 2, 'MarkerSize', 6);
    hold on;
    plot(1:length(Y_pred), Y_pred, 'r-s', 'LineWidth', 2, 'MarkerSize', 6);
    grid on;
    xlabel('Data Point');
    ylabel('Nilai Risiko');
    title('Perbandingan Actual vs Predicted');
    legend('Actual', 'Predicted', 'Location', 'best');
    
    % Menambahkan MSE ke plot
    text(0.5, 0.95, sprintf('MSE: %.4f', mse), 'Units', 'normalized', ...
        'HorizontalAlignment', 'center', 'FontSize', 12, 'FontWeight', 'bold');
    
    % Menyimpan plot
    saveas(gcf, '../images/Actual_vs_Prediksi.png');
    fprintf('   Gambar disimpan: ../images/Actual_vs_Prediksi.png\n');
    
else
    fprintf('   File data_uji.csv tidak ditemukan.\n');
    fprintf('   Letakkan file data_uji.csv di folder ../../data/raw/\n');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 10. MENAMPILKAN ATURAN FUZZY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf('10. Menampilkan aturan fuzzy...\n\n');

% Menampilkan aturan fuzzy dalam format teks
rules = fis.rule;
for i = 1:length(rules)
    antecedent = rules(i).antecedent;
    consequent = rules(i).consequent;
    weight = rules(i).weight;
    connection = rules(i).connection;
    
    % Mendapatkan nama linguistik untuk antecedent
    str_antecedent = '';
    for j = 1:length(antecedent)
        if antecedent(j) > 0
            var_name = fis.input(j).name;
            mf_name = fis.input(j).mf(antecedent(j)).name;
            if j > 1
                if connection == 1
                    str_antecedent = [str_antecedent ' DAN '];
                else
                    str_antecedent = [str_antecedent ' ATAU '];
                end
            end
            str_antecedent = [str_antecedent var_name ' ' mf_name];
        end
    end
    
    % Mendapatkan nama linguistik untuk consequent
    var_name = fis.output(1).name;
    mf_name = fis.output(1).mf(consequent).name;
    str_consequent = [var_name ' ' mf_name];
    
    % Menampilkan aturan
    fprintf('Aturan %d: JIKA %s MAKA %s (Weight: %.1f)\n', ...
            i, str_antecedent, str_consequent, weight);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 11. MEMBUAT FILE TEKS DENGAN ATURAN FUZZY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf('\n11. Menyimpan aturan fuzzy ke file teks...\n');

% Membuka file untuk ditulis
fid = fopen('../../documentation/aturan_fuzzy.txt', 'w');

fprintf(fid, 'ATURAN FUZZY - SISTEM PENILAIAN RISIKO LAPTOP\n');
fprintf(fid, '=============================================\n\n');
fprintf(fid, 'Dibuat oleh: Kelompok 02 - Kelas 5D\n');
fprintf(fid, 'Tanggal: %s\n\n', datestr(now()));

for i = 1:length(rules)
    antecedent = rules(i).antecedent;
    consequent = rules(i).consequent;
    weight = rules(i).weight;
    connection = rules(i).connection;
    
    % Mendapatkan nama linguistik untuk antecedent
    str_antecedent = '';
    for j = 1:length(antecedent)
        if antecedent(j) > 0
            var_name = fis.input(j).name;
            mf_name = fis.input(j).mf(antecedent(j)).name;
            if j > 1
                if connection == 1
                    str_antecedent = [str_antecedent ' DAN '];
                else
                    str_antecedent = [str_antecedent ' ATAU '];
                end
            end
            str_antecedent = [str_antecedent var_name ' ' mf_name];
        end
    end
    
    % Mendapatkan nama linguistik untuk consequent
    var_name = fis.output(1).name;
    mf_name = fis.output(1).mf(consequent).name;
    str_consequent = [var_name ' ' mf_name];
    
    % Menulis aturan ke file
    fprintf(fid, 'Aturan %d: JIKA %s MAKA %s (Weight: %.1f)\n', ...
            i, str_antecedent, str_consequent, weight);
end

fclose(fid);
fprintf('   Aturan fuzzy disimpan: ../../documentation/aturan_fuzzy.txt\n');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 12. MENAMPILKAN INFORMASI SISTEM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf('\n12. Informasi sistem fuzzy:\n');
fprintf('    - Nama sistem: %s\n', fis.name);
fprintf('    - Tipe sistem: %s\n', fis.type);
fprintf('    - Metode AND: %s\n', fis.andMethod);
fprintf('    - Metode OR: %s\n', fis.orMethod);
fprintf('    - Metode Implikasi: %s\n', fis.impMethod);
fprintf('    - Metode Agregasi: %s\n', fis.aggMethod);
fprintf('    - Metode Defuzzifikasi: %s\n', fis.defuzzMethod);
fprintf('    - Jumlah aturan: %d\n', length(fis.rule));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 13. MENUTUP PROGRAM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf('\n==================================================\n');
fprintf('PROGRAM SELESAI DIJALANKAN\n');
fprintf('==================================================\n');

% Menyimpan workspace
save('RiskLaptop_workspace.oct');
fprintf('Workspace disimpan: RiskLaptop_workspace.oct\n');