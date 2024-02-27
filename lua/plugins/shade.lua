return {
	"sunjon/shade.nvim",
	config = function()
		require("shade").setup({
			overlay_opacity = 70,
			opacity_step = 1,
		})
	end,
}
