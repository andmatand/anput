function concat_tables(tableList)
    combined = {}
    for _, t in ipairs(tableList) do
        for _, v in ipairs(t) do
            table.insert(combined, v)
        end
    end
    return combined
end

function copy_table(tbl)
    new = {}
    for k, v in pairs(tbl) do
        new[k] = v
    end

    return new
end

function remove_value_from_table(value, tbl)
    for k, v in pairs(tbl) do
        if v == value then
            table.remove(tbl, k)
            break
        end
    end
end

function value_in_table(value, tbl)
    for _, v in pairs(tbl) do
        if v == value then
            return true
        end
    end

    return false
end
