function concat_tables(tableList)
    local combined = {}
    for _, t in ipairs(tableList) do
        for _, v in ipairs(t) do
            table.insert(combined, v)
        end
    end
    return combined
end

function copy_table(tbl)
    local new = {}
    for k, v in pairs(tbl) do
        new[k] = v
    end

    return new
end

function remove_value_from_table(value, tbl)
    for k, v in pairs(tbl) do
        if v == value then
            table.remove(tbl, k)
            return
        end
    end
end

function search_table(tbl, search)
    for _, item in pairs(tbl) do
        for key, value in pairs(search) do
            if item[key] == value then
                return item
            end
        end
    end
end

function serialize_table(tbl)
    local str = '{'
    local i = 0
    for k, v in pairs(tbl) do
        i = i + 1
        if i > 1 then
            str = str .. ', '
        end

        str = str .. k .. ' = '

        if type(v) == 'string' then
            str = str .. "'" .. v .. "'"
        elseif type(v) == 'number' then
            str = str .. v
        elseif type(v) == 'table' then
            str = str .. serialize_table(v)
        elseif type(v) == 'boolean' then
            str = str .. tostring(v)
        end
    end
    str = str .. '}'

    return str
end

function tables_have_equal_values(t1, t2)
    for k, v in pairs(t1) do
        if v ~= t2[k] then
            return false
        end
    end

    return true
end

function value_in_table(value, tbl)
    for _, v in pairs(tbl) do
        if v == value then
            return true
        end
    end

    return false
end
