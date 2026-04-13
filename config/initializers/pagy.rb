require "pagy/extras/overflow"
require "pagy/extras/limit"

Pagy::DEFAULT[:limit]    = 20
Pagy::DEFAULT[:overflow] = :last_page
