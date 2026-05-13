function  save_code(code_str)

if isempty(code_str)
    fprintf(' -> LLM 未返回代码，跳过本次尝试...\n');
    return 
end

% 步骤 B-1：覆盖主线文件，供 sol_TSP_GA 直接调用
fid = fopen('llm_smart_crossover.m', 'w');
fprintf(fid, '%s', code_str);
fclose(fid);

% 步骤 B-2：按时间戳归档保存本次生成的代码
timeStamp = datestr(now, 'yyyymmdd_HHMMSS');
archiveFileName = sprintf('history_operators/crossover_%s.m',  timeStamp);
fid_archive = fopen(archiveFileName, 'w');
fprintf(fid_archive, '%s', code_str);
fclose(fid_archive);