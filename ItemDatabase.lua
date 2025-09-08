-- 缓存物品名称
local nameCache = {}
local chineseNameCache = {} -- 新增：缓存中文名称到物品ID的映射

-- 获取物品名称（通过ID）
local function getItemName(id)
    if nameCache[id] then
        return nameCache[id]
    end
    for i = 1, 33 do
        local chunkTable = _G["ItemNames_" .. i]
        if chunkTable and chunkTable[id] then
            local name
            if type(chunkTable[id]) == "string" then
                -- 旧格式：直接是英文名称
                name = chunkTable[id]
            elseif type(chunkTable[id]) == "table" and chunkTable[id].en then
                -- 新格式：包含 en 和 zh 的表
                name = chunkTable[id].en
            else
                name = "未知物品"
            end
            nameCache[id] = name
            return name
        end
    end
    print("错误：物品 ID " .. id .. " 不存在于数据库")
    nameCache[id] = "未知物品"
    return "未知物品"
end

-- 通过中文名称获取物品ID和英文名称
local function getItemIdByChineseName(chineseName)
    if chineseNameCache[chineseName] then
        local id = chineseNameCache[chineseName]
        return id, getItemName(id)
    end
    for i = 1, 33 do
        local chunkTable = _G["ItemNames_" .. i]
        if chunkTable then
            for id, data in pairs(chunkTable) do
                if type(data) == "table" and data.zh == chineseName then
                    local name = data.en or " risch未知物品"
                    chineseNameCache[chineseName] = id
                    nameCache[id] = name
                    return id, name
                end
            end
        end
    end
    return nil, "未找到物品"
end

-- 定义弹窗
StaticPopupDialogs["COPY_ENGLISH_NAME"] = {
    text = "物品英文名称（已选中，可直接复制）：",
    button1 = "确定",
    hasEditBox = true,
    OnShow = function(self, data)
        local editBox = self.editBox
        editBox:SetText(data.name)
        editBox:HighlightText()  -- 选中全部文本
        editBox:SetFocus()      -- 聚焦输入框
    end,
    EditBoxOnEnterPressed = function(self)
        self:GetParent():Hide()  -- 按 Enter 关闭弹窗
    end,
    EditBoxOnEscapePressed = function(self)
        self:GetParent():Hide()  -- 按 Esc 关闭弹窗
    end,
    OnAccept = function(self)
        -- 点击“确定”关闭弹窗
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,  -- 避免与其他弹窗冲突
}

-- Slash 命令处理
SLASH_ENGLISHNAME1 = "/en"
SlashCmdList["ENGLISHNAME"] = function(msg)
    -- 清理输入，去除前后空格
    msg = strtrim(msg)
    
    -- 尝试匹配物品链接或ID
    local itemId = msg:match("item:(%d+)") or msg:match("^(%d+)$")
    if itemId then
        local name = getItemName(itemId)
        StaticPopup_Show("COPY_ENGLISH_NAME", nil, nil, {name = name})
        return
    end
    
    -- 如果不是链接或ID，尝试作为中文名称查询
    if msg ~= "" then
        local id, name = getItemIdByChineseName(msg)
        if id then
            StaticPopup_Show("COPY_ENGLISH_NAME", nil, nil, {name = name})
        else
            print("错误：未找到名为 '" .. msg .. "' 的物品")
        end
        return
    end
    
    -- 输入为空，显示用法
    print("用法: /en [itemlink] 或 /en <itemId> 或 /en <中文名称>")
end

-- 调试命令：检查表是否加载
SLASH_DEBUGTABLES1 = "/debugtables"
SlashCmdList["DEBUGTABLES"] = function()
    for i = 1, 33 do
        local tableName = "ItemNames_" .. i
        print("表 " .. tableName .. ": " .. (_G[tableName] and "已加载" or "未加载"))
    end
end