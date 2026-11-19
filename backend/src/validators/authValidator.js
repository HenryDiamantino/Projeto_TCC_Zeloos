const { body } = require('express-validator');

const FOTO_PERFIL_MAX_BYTES = 512 * 1024;

const assinaturasImagem = {
  'image/png': (imagem) => imagem.subarray(0, 8).equals(Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])),
  'image/jpeg': (imagem) => imagem[0] === 0xff && imagem[1] === 0xd8 && imagem[2] === 0xff,
  'image/webp': (imagem) => imagem.toString('latin1', 0, 4) === 'RIFF' && imagem.toString('latin1', 8, 12) === 'WEBP',
};

function isFotoPerfilValida(value) {
  const partes = typeof value === 'string' && /^data:(image\/(?:png|jpeg|webp));base64,([A-Za-z0-9+/]+={0,2})$/.exec(value);
  if (!partes) return false;
  const imagem = Buffer.from(partes[2], 'base64');
  return imagem.length <= FOTO_PERFIL_MAX_BYTES && assinaturasImagem[partes[1]](imagem);
}

const nomeRule = () => body('nome').trim().isLength({ min: 2 }).withMessage('Nome deve ter pelo menos 2 caracteres.');

const telefoneRule = () => body('telefone')
  .optional({ values: 'falsy' })
  .trim()
  .matches(/^[0-9()+\-\s]+$/)
  .custom((value) => /^\d{10,13}$/.test(value.replace(/\D/g, '')))
  .withMessage('Telefone inválido. Informe DDD e número.');

const registerValidation = [
  nomeRule(),
  body('email').isEmail().withMessage('E-mail inválido.'),
  body('senha').isLength({ min: 6 }).withMessage('Senha deve ter pelo menos 6 caracteres.'),
  telefoneRule(),
];

const updateProfileValidation = [nomeRule(), telefoneRule()];

const fotoPerfilValidation = [
  body('foto_perfil')
    .custom(isFotoPerfilValida)
    .withMessage('Envie uma imagem PNG, JPEG ou WEBP de até 512 KB.'),
];

const loginValidation = [
  body('email').isEmail().withMessage('E-mail inválido.'),
  body('senha').notEmpty().withMessage('Senha obrigatória.'),
];

module.exports = { registerValidation, loginValidation, updateProfileValidation, fotoPerfilValidation };
