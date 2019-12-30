

function check_threshold(old, new, threshold = 64)
if old < threshold and new >= threshold then
    return 1
  elseif old >= threshold and new < threshold then
    return 0
  end
  return -1
end