# frozen_string_literal: true

# 'readme.md' -> ['README.MD', 'README.md', 'readme.MD', 'readme.md']
# (or a permutation of this list).
#
# 'MiXeD' -> ['MIXED', 'mixed', 'MiXeD'] (or a permutation thereof).
def case_combinations(path, sep = '.')
  h, t = path.split(sep, 2)
  hs = [h.upcase, h.downcase, h].uniq
  return hs unless t
  case_combinations(t).map { |t0| hs.map { |h0| [h0, t0].join('.') } }.flatten
end
