local M = {}

local function extract(path)
  for _, tag in ipairs({ "-PreviewImage", "-ThumbnailImage" }) do
    local child = Command("exiftool")
      :args({ "-b", tag, tostring(path) })
      :stdout(Command.PIPED)
      :stderr(Command.NULL)
      :spawn()
    if child then
      local out = child:wait_with_output()
      if out and out.status.success and out.stdout ~= "" then
        return out.stdout
      end
    end
  end
  return nil
end

function M:peek(job)
  local cache = ya.file_cache(job)
  if not cache then return end

  if fs.cha(cache) then
    return ya.image_show(cache, job.area)
  end

  local jpeg = extract(job.file.url)
  if not jpeg then
    return ya.preview_widgets(job, {
      ui.Text(ui.Line("arw: no embedded preview found")):area(job.area)
    })
  end

  local f = io.open(tostring(cache), "wb")
  if f then
    f:write(jpeg)
    f:close()
    ya.image_show(cache, job.area)
  end
end

function M:seek() end

return M
local M = {}

local function extract(path)
  for _, tag in ipairs({ "-PreviewImage", "-ThumbnailImage" }) do
    local output = Command("exiftool")
      :arg("-b")
      :arg(tag)
      :arg(tostring(path))
      :stdout(Command.PIPED)
      :stderr(Command.NULL)
      :output()

    if output and output.stdout ~= "" then
      return output.stdout
    end
  end
  return nil
end

function M:peek(job)
  local cache = ya.file_cache(job)
  if not cache then return end

  if fs.cha(cache) then
    return ya.image_show(cache, job.area)
  end

  local jpeg = extract(job.file.url)
  if not jpeg then
    return ya.preview_widgets(job, {
      ui.Text(ui.Line("arw: no embedded preview found")):area(job.area)
    })
  end

  local f = io.open(tostring(cache), "wb")
  if f then
    f:write(jpeg)
    f:close()
    ya.image_show(cache, job.area)
  end
end

function M:seek() end

return M
